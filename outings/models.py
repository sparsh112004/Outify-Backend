from django.conf import settings
from django.db import models


class OutingRequest(models.Model):
    class Status(models.TextChoices):
        PENDING = 'pending'
        APPROVED = 'approved'
        DENIED = 'denied'

    class OverallStatus(models.TextChoices):
        PENDING_PARENT = 'pending_parent'
        PENDING_FACULTY = 'pending_faculty'
        PENDING_WARDEN = 'pending_warden'
        APPROVED = 'approved'
        OUT = 'out'
        DENIED_BY_PARENT = 'denied_by_parent'
        DENIED_BY_FACULTY = 'denied_by_faculty'
        DENIED_BY_WARDEN = 'denied_by_warden'
        COMPLETED = 'completed'
        EXPIRED = 'expired'
        CANCELLED = 'cancelled'

    student = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='outing_requests')
    reason = models.TextField()
    departure_datetime = models.DateTimeField()
    expected_return_datetime = models.DateTimeField()
    destination = models.TextField(null=True, blank=True)
    department = models.ForeignKey('accounts.Department', on_delete=models.SET_NULL, null=True, blank=True, related_name='outing_requests')

    room_number = models.CharField(max_length=20, null=True, blank=True)
    room_details = models.TextField(null=True, blank=True)

    faculty = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='faculty_processed_outings')
    faculty_status = models.CharField(max_length=20, choices=Status.choices, default=Status.PENDING)
    faculty_remarks = models.TextField(null=True, blank=True)
    faculty_processed_at = models.DateTimeField(null=True, blank=True)

    warden = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='warden_processed_outings')
    warden_status = models.CharField(max_length=20, choices=Status.choices, default=Status.PENDING)
    warden_remarks = models.TextField(null=True, blank=True)
    warden_processed_at = models.DateTimeField(null=True, blank=True)

    security = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='security_verified_outings')
    actual_departure_time = models.DateTimeField(null=True, blank=True)
    actual_return_time = models.DateTimeField(null=True, blank=True)
    security_remarks = models.TextField(null=True, blank=True)

    overall_status = models.CharField(max_length=30, choices=OverallStatus.choices, default=OverallStatus.PENDING_PARENT)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        indexes = [
            models.Index(fields=['student', 'created_at']),
            models.Index(fields=['overall_status', 'departure_datetime']),
            models.Index(fields=['expected_return_datetime', 'actual_return_time']),
        ]

    def __str__(self):
        return f'OutingRequest#{self.id} student={self.student_id} status={self.overall_status}'
