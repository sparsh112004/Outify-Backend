from django.db import transaction
from django.utils import timezone
from rest_framework import status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from accounts.permissions import IsFaculty, IsSecurity, IsStudent, IsWarden
from auditlog.models import Log
from outings.models import OutingRequest
from outings.serializers import (
    FacultyDecisionSerializer,
    OutingRequestCreateSerializer,
    OutingRequestDetailSerializer,
    OutingRequestListSerializer,
    SecurityVerifySerializer,
    WardenDecisionSerializer,
)


def _log(user, action, details=None):
    Log.objects.create(user=user, action=action, details=details or {})


class StudentCreateOutingView(APIView):
    permission_classes = [IsAuthenticated, IsStudent]

    def post(self, request):
        serializer = OutingRequestCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        outing = serializer.save(student=request.user)
        
        # Logic for Parent Approval vs Notification
        # Permission is ONLY required if outing > 2 days (48 hours)
        duration = outing.expected_return_datetime - outing.departure_datetime
        needs_approval = duration.total_seconds() > (2 * 24 * 3600)
        
        has_parent_email = bool(outing.student.parent_email)
        
        if not has_parent_email:
            # If no email, we cannot get permission, so we skip to faculty
            outing.overall_status = OutingRequest.OverallStatus.PENDING_FACULTY
        elif needs_approval:
            # Requires parent to click the magic link
            outing.overall_status = OutingRequest.OverallStatus.PENDING_PARENT
            approval_url = f"http://localhost:8000/api/requests/{outing.id}/parent-approve"
            denial_url = f"http://localhost:8000/api/requests/{outing.id}/parent-deny"
            print("\n" + "="*50)
            print(f"APPROVAL REQUEST TO PARENT ({outing.student.parent_email})")
            print(f"Subject: Outing Approval Request for {outing.student.name}")
            print(f"Duration: {duration}")
            print(f"Please approve or deny the request using these links:")
            print(f"APPROVE: {approval_url}")
            print(f"DENY: {denial_url}")
            print("="*50 + "\n")
        else:
            # Shorter outings - just inform the parent and move to faculty
            outing.overall_status = OutingRequest.OverallStatus.PENDING_FACULTY
            print("\n" + "="*50)
            print(f"INFORMATIONAL EMAIL TO PARENT ({outing.student.parent_email})")
            print(f"Subject: Outing Notification for {outing.student.name}")
            print(f"Your ward has submitted an outing request for {duration}.")
            print("No action is required from your side as the duration is 2 days or less.")
            print("="*50 + "\n")

        outing.save()
        _log(request.user, 'outing_submitted', {'outing_request_id': outing.id})
        return Response(OutingRequestDetailSerializer(outing).data, status=status.HTTP_201_CREATED)


class StudentOutingsListView(APIView):
    permission_classes = [IsAuthenticated, IsStudent]

    def get(self, request):
        qs = OutingRequest.objects.filter(student=request.user).order_by('-created_at')
        return Response(OutingRequestListSerializer(qs, many=True).data, status=status.HTTP_200_OK)


class OutingDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        try:
            outing = OutingRequest.objects.select_related('student').get(pk=pk)
        except OutingRequest.DoesNotExist:
            return Response({'detail': 'Not found'}, status=status.HTTP_404_NOT_FOUND)

        if request.user.role == 'student' and outing.student_id != request.user.id:
            return Response({'detail': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)

        if request.user.role in ['student', 'faculty', 'warden', 'security', 'admin']:
            return Response(OutingRequestDetailSerializer(outing).data, status=status.HTTP_200_OK)

        return Response({'detail': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)


class ParentDecideView(APIView):
    permission_classes = [AllowAny] # No auth required for the magic link for now, or we could use tokens

    def get(self, request, pk, action):
        try:
            outing = OutingRequest.objects.get(pk=pk)
        except OutingRequest.DoesNotExist:
            return Response("Request not found", status=status.HTTP_404_NOT_FOUND)

        if outing.overall_status != OutingRequest.OverallStatus.PENDING_PARENT:
            return Response("Request is no longer pending parent approval", status=status.HTTP_400_BAD_REQUEST)

        if action == 'approve':
            outing.overall_status = OutingRequest.OverallStatus.PENDING_FACULTY
            outing.save()
            return Response("You have APPROVED the outing request. It will now be processed by college faculty.")
        elif action == 'deny':
            outing.overall_status = OutingRequest.OverallStatus.DENIED_BY_PARENT
            outing.save()
            return Response("You have DENIED the outing request. The student has been notified.")
        
        return Response("Invalid action", status=status.HTTP_400_BAD_REQUEST)


class FacultyPendingListView(APIView):
    permission_classes = [IsAuthenticated, IsFaculty]

    def get(self, request):
        # Faculty sees requests pending their approval OR awaiting parent approval
        qs = OutingRequest.objects.filter(
            overall_status__in=[
                OutingRequest.OverallStatus.PENDING_FACULTY,
                OutingRequest.OverallStatus.PENDING_PARENT,
            ],
            faculty=request.user,
        ).order_by('-created_at')
        return Response(OutingRequestListSerializer(qs, many=True).data, status=status.HTTP_200_OK)


class FacultyDecideView(APIView):
    permission_classes = [IsAuthenticated, IsFaculty]

    def post(self, request, pk):
        serializer = FacultyDecisionSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        with transaction.atomic():
            try:
                outing = OutingRequest.objects.select_for_update().get(pk=pk)
            except OutingRequest.DoesNotExist:
                return Response({'detail': 'Not found'}, status=status.HTTP_404_NOT_FOUND)

            if outing.overall_status != OutingRequest.OverallStatus.PENDING_FACULTY:
                return Response({'detail': 'Invalid state'}, status=status.HTTP_400_BAD_REQUEST)

            decision = serializer.validated_data['decision']
            remarks = serializer.validated_data.get('remarks')

            outing.faculty = request.user
            outing.faculty_status = decision
            outing.faculty_remarks = remarks
            outing.faculty_processed_at = timezone.now()

            if decision == OutingRequest.Status.APPROVED:
                outing.overall_status = OutingRequest.OverallStatus.PENDING_WARDEN
            else:
                outing.overall_status = OutingRequest.OverallStatus.DENIED_BY_FACULTY

            outing.save()

        _log(request.user, 'faculty_decision', {'outing_request_id': outing.id, 'decision': decision})
        return Response(OutingRequestDetailSerializer(outing).data, status=status.HTTP_200_OK)


class WardenPendingListView(APIView):
    permission_classes = [IsAuthenticated, IsWarden]

    def get(self, request):
        qs = OutingRequest.objects.filter(overall_status=OutingRequest.OverallStatus.PENDING_WARDEN).order_by('-created_at')
        return Response(OutingRequestListSerializer(qs, many=True).data, status=status.HTTP_200_OK)


class WardenDecideView(APIView):
    permission_classes = [IsAuthenticated, IsWarden]

    def post(self, request, pk):
        serializer = WardenDecisionSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        with transaction.atomic():
            try:
                outing = OutingRequest.objects.select_for_update().get(pk=pk)
            except OutingRequest.DoesNotExist:
                return Response({'detail': 'Not found'}, status=status.HTTP_404_NOT_FOUND)

            if outing.overall_status != OutingRequest.OverallStatus.PENDING_WARDEN:
                return Response({'detail': 'Invalid state'}, status=status.HTTP_400_BAD_REQUEST)

            decision = serializer.validated_data['decision']
            email_parent = serializer.validated_data.get('email_parent', False)
            outing.room_number = serializer.validated_data['room_number']
            outing.room_details = serializer.validated_data['room_details']
            outing.warden = request.user
            outing.warden_status = decision
            outing.warden_remarks = serializer.validated_data.get('remarks')
            outing.warden_processed_at = timezone.now()

            if decision == OutingRequest.Status.APPROVED:
                outing.overall_status = OutingRequest.OverallStatus.APPROVED
                if email_parent and outing.student.parent_email:
                    print("\n" + "="*50)
                    print(f"CONFIRMATION EMAIL TO PARENT ({outing.student.parent_email})")
                    print(f"Subject: Outing Request APPROVED for {outing.student.name}")
                    print(f"Your ward's outing has been approved by the Warden.")
                    print("="*50 + "\n")
            else:
                outing.overall_status = OutingRequest.OverallStatus.DENIED_BY_WARDEN

            outing.save()

        _log(request.user, 'warden_decision', {'outing_request_id': outing.id, 'decision': decision})
        return Response(OutingRequestDetailSerializer(outing).data, status=status.HTTP_200_OK)


class SecurityTodayListView(APIView):
    permission_classes = [IsAuthenticated, IsSecurity]

    def get(self, request):
        # Show all approved (waiting to leave) and out (waiting to return) requests.
        # We don't strictly filter by 'today' anymore to give security visibility 
        # into upcoming approved outings and students who might have stayed out longer.
        qs = OutingRequest.objects.filter(
            overall_status__in=[
                OutingRequest.OverallStatus.APPROVED,
                OutingRequest.OverallStatus.OUT
            ]
        ).order_by('departure_datetime')
        return Response(OutingRequestListSerializer(qs, many=True).data, status=status.HTTP_200_OK)


class SecurityVerifyView(APIView):
    permission_classes = [IsAuthenticated, IsSecurity]

    def post(self, request, pk):
        serializer = SecurityVerifySerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        action = serializer.validated_data['action']

        with transaction.atomic():
            try:
                outing = OutingRequest.objects.select_for_update().get(pk=pk)
            except OutingRequest.DoesNotExist:
                return Response({'detail': 'Not found'}, status=status.HTTP_404_NOT_FOUND)

            # Security can verify:
            # 1. EXIT if status is APPROVED
            # 2. ENTRY if status is OUT
            if action == 'exit' and outing.overall_status != OutingRequest.OverallStatus.APPROVED:
                return Response({'detail': 'Request must be APPROVED to verify exit.'}, status=status.HTTP_400_BAD_REQUEST)
            if action == 'entry' and outing.overall_status != OutingRequest.OverallStatus.OUT:
                return Response({'detail': 'Student must be OUT to verify entry.'}, status=status.HTTP_400_BAD_REQUEST)

            now = timezone.now()
            outing.security = request.user

            if action == 'exit':
                outing.actual_departure_time = now
                outing.overall_status = OutingRequest.OverallStatus.OUT
                outing.save(update_fields=['security', 'actual_departure_time', 'overall_status', 'updated_at'])
            else:
                outing.actual_return_time = now
                outing.overall_status = OutingRequest.OverallStatus.COMPLETED
                outing.save(update_fields=['security', 'actual_return_time', 'overall_status', 'updated_at'])

        if action == 'exit':
            _log(request.user, 'security_exit_verified', {'outing_request_id': outing.id})
        else:
            _log(request.user, 'security_entry_verified', {'outing_request_id': outing.id})

        return Response(OutingRequestDetailSerializer(outing).data, status=status.HTTP_200_OK)


class SecurityScanLookupView(APIView):
    permission_classes = [IsAuthenticated, IsSecurity]

    def get(self, request, user_id):
        # Look for an active request for this student today
        # Active means either 'approved' (ready to exit) or 'out' (ready to enter)
        today = timezone.localdate()
        
        # We also check if it's the expected departure/return date to be precise, 
        # but usually 'approved' or 'out' is enough to identify the *current* activity.
        qs = OutingRequest.objects.filter(
            student_id=user_id,
            overall_status__in=[
                OutingRequest.OverallStatus.APPROVED,
                OutingRequest.OverallStatus.OUT
            ]
        ).order_by('-created_at')

        # Filter by today's date if possible, but let's be flexible to identify the active one
        outing = qs.first()
        
        if not outing:
            return Response({'detail': 'No active approved outing found for this student.'}, status=status.HTTP_404_NOT_FOUND)

        return Response(OutingRequestDetailSerializer(outing).data, status=status.HTTP_200_OK)


class StudentCancelOutingView(APIView):
    permission_classes = [IsAuthenticated, IsStudent]

    def post(self, request, pk):
        with transaction.atomic():
            try:
                outing = OutingRequest.objects.select_for_update().get(pk=pk, student=request.user)
            except OutingRequest.DoesNotExist:
                return Response({'detail': 'Not found'}, status=status.HTTP_404_NOT_FOUND)

            if outing.overall_status not in (
                OutingRequest.OverallStatus.PENDING_PARENT,
                OutingRequest.OverallStatus.PENDING_FACULTY,
                OutingRequest.OverallStatus.PENDING_WARDEN,
            ):
                return Response({'detail': 'Cannot cancel — request is no longer pending'}, status=status.HTTP_400_BAD_REQUEST)

            outing.overall_status = OutingRequest.OverallStatus.CANCELLED
            outing.save(update_fields=['overall_status', 'updated_at'])

        _log(request.user, 'outing_cancelled', {'outing_request_id': outing.id})
        return Response(OutingRequestDetailSerializer(outing).data, status=status.HTTP_200_OK)
