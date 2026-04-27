from datetime import timedelta

from celery import shared_task
from django.db import transaction
from django.utils import timezone

from auditlog.models import Log
from notifications.models import Notification
from outings.models import OutingRequest


def _log(user, action, details=None):
    Log.objects.create(user=user, action=action, details=details or {})


@shared_task
def auto_expire_requests():
    """Mark pending requests as expired once their departure time has passed."""
    now = timezone.now()
    expired_qs = OutingRequest.objects.filter(
        overall_status__in=[
            OutingRequest.OverallStatus.PENDING_FACULTY,
            OutingRequest.OverallStatus.PENDING_WARDEN,
        ],
        departure_datetime__lt=now,
    )
    count = expired_qs.update(overall_status=OutingRequest.OverallStatus.EXPIRED)
    if count:
        Log.objects.create(user=None, action='auto_expire_requests', details={'expired_count': count})


def _send_email(user, title, body):
    # Uses Django EMAIL_* settings. Kept simple; failures are recorded in Notification.status.
    from django.core.mail import send_mail
    from django.conf import settings

    send_mail(
        subject=title,
        message=body,
        from_email=settings.DEFAULT_FROM_EMAIL,
        recipient_list=[user.email],
        fail_silently=False,
    )


def _send_push(user, title, body):
    # Optional: requires Firebase Admin service account JSON.
    from django.conf import settings

    service_account_path = getattr(settings, 'FIREBASE_SERVICE_ACCOUNT_JSON_PATH', '')
    if not service_account_path:
        raise RuntimeError('FIREBASE_SERVICE_ACCOUNT_JSON_PATH is not configured')

    import firebase_admin
    from firebase_admin import credentials, messaging

    if not firebase_admin._apps:
        cred = credentials.Certificate(service_account_path)
        firebase_admin.initialize_app(cred)

    if not user.fcm_token:
        raise RuntimeError('User does not have fcm_token')

    message = messaging.Message(
        token=user.fcm_token,
        notification=messaging.Notification(title=title, body=body),
        data={},
    )
    messaging.send(message)


@shared_task
def send_return_reminders_strict():
    now = timezone.now()

    # Strict matching (minute precision): find items whose expected_return minute matches now+30 or now+15.
    # Note: strict matching can miss if clock drift / scheduler delays.
    targets = [now + timedelta(minutes=30), now + timedelta(minutes=15)]

    for target in targets:
        start = target.replace(second=0, microsecond=0)
        end = start + timedelta(minutes=1)

        qs = OutingRequest.objects.select_related('student').filter(
            overall_status__in=[
                OutingRequest.OverallStatus.APPROVED,
                OutingRequest.OverallStatus.OUT
            ],
            actual_return_time__isnull=True,
            expected_return_datetime__gte=start,
            expected_return_datetime__lt=end,
        )

        for outing in qs:
            student = outing.student
            minutes = 30 if start == targets[0].replace(second=0, microsecond=0) else 15
            title = 'Return Reminder'
            body = f'You are expected to return in {minutes} minutes.'

            with transaction.atomic():
                # Email
                email_status = 'sent'
                try:
                    _send_email(student, title, body)
                except Exception as e:
                    email_status = 'failed'
                    _log(student, 'reminder_email_failed', {'outing_request_id': outing.id, 'error': str(e), 'minutes': minutes})
                else:
                    _log(student, 'reminder_email_sent', {'outing_request_id': outing.id, 'minutes': minutes})

                Notification.objects.create(
                    user=student,
                    type=Notification.Type.EMAIL,
                    title=title,
                    body=body,
                    status=email_status,
                )

                # Push (best-effort)
                push_status = 'sent'
                try:
                    _send_push(student, title, body)
                except Exception as e:
                    push_status = 'failed'
                    _log(student, 'reminder_push_failed', {'outing_request_id': outing.id, 'error': str(e), 'minutes': minutes})
                else:
                    _log(student, 'reminder_push_sent', {'outing_request_id': outing.id, 'minutes': minutes})

                Notification.objects.create(
                    user=student,
                    type=Notification.Type.PUSH,
                    title=title,
                    body=body,
                    status=push_status,
                )
