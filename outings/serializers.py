from django.db.models import Q
from rest_framework import serializers

from accounts.models import Department
from outings.models import OutingRequest


class OutingRequestCreateSerializer(serializers.ModelSerializer):
    department = serializers.SlugRelatedField(slug_field='name', queryset=Department.objects.all(), required=False, allow_null=True)
    
    class Meta:
        model = OutingRequest
        fields = ['id', 'reason', 'departure_datetime', 'expected_return_datetime', 'destination', 'room_number', 'faculty', 'department']

    def validate(self, attrs):
        request = self.context.get('request')
        if not request or not request.user:
            return attrs

        student = request.user
        departure = attrs.get('departure_datetime')
        expected_return = attrs.get('expected_return_datetime')

        if departure and expected_return:
            if departure >= expected_return:
                raise serializers.ValidationError("Departure time must be before return time.")

            # Check for overlapping requests
            # Overlap condition: (existing_start < new_end) AND (existing_end > new_start)
            overlapping = OutingRequest.objects.filter(
                student=student,
                overall_status__in=[
                    OutingRequest.OverallStatus.PENDING_PARENT,
                    OutingRequest.OverallStatus.PENDING_FACULTY,
                    OutingRequest.OverallStatus.PENDING_WARDEN,
                    OutingRequest.OverallStatus.APPROVED,
                    OutingRequest.OverallStatus.OUT,
                ]
            ).filter(
                Q(departure_datetime__lt=expected_return) & 
                Q(expected_return_datetime__gt=departure)
            )

            if overlapping.exists():
                raise serializers.ValidationError(
                    "You already have an active or pending outing request that overlaps with these dates."
                )

        return attrs


class OutingRequestListSerializer(serializers.ModelSerializer):
    class Meta:
        model = OutingRequest
        fields = [
            'id',
            'reason',
            'departure_datetime',
            'expected_return_datetime',
            'destination',
            'overall_status',
            'faculty_status',
            'warden_status',
            'created_at',
            'updated_at',
        ]


class OutingRequestDetailSerializer(serializers.ModelSerializer):
    student = serializers.SerializerMethodField()
    department = serializers.SlugRelatedField(slug_field='name', read_only=True)

    class Meta:
        model = OutingRequest
        fields = [
            'id',
            'student',
            'reason',
            'departure_datetime',
            'expected_return_datetime',
            'destination',
            'room_number',
            'room_details',
            'department',
            'faculty_status',
            'faculty_remarks',
            'faculty_processed_at',
            'warden_status',
            'warden_remarks',
            'warden_processed_at',
            'actual_departure_time',
            'actual_return_time',
            'overall_status',
            'created_at',
            'updated_at',
        ]

    def get_student(self, obj):
        s = obj.student
        return {
            'id': s.id,
            'name': s.name,
            'email': s.email,
            'college_id': s.college_id,
            'room_number': s.room_number,
            'parent_email': s.parent_email,
            'profile_pic': s.profile_pic.url if s.profile_pic else None,
        }


class FacultyDecisionSerializer(serializers.Serializer):
    decision = serializers.ChoiceField(choices=['approved', 'denied'])
    remarks = serializers.CharField(required=False, allow_blank=True, allow_null=True)


class WardenDecisionSerializer(serializers.Serializer):
    decision = serializers.ChoiceField(choices=['approved', 'denied'])
    room_number = serializers.CharField()
    room_details = serializers.CharField()
    remarks = serializers.CharField(required=False, allow_blank=True, allow_null=True)
    email_parent = serializers.BooleanField(default=False)


class SecurityVerifySerializer(serializers.Serializer):
    action = serializers.ChoiceField(choices=['exit', 'entry'])
