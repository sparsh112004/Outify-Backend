from rest_framework import serializers

from accounts.models import Department
from outings.models import OutingRequest


class OutingRequestCreateSerializer(serializers.ModelSerializer):
    department = serializers.SlugRelatedField(slug_field='name', queryset=Department.objects.all(), required=False, allow_null=True)
    
    class Meta:
        model = OutingRequest
        fields = ['id', 'reason', 'departure_datetime', 'expected_return_datetime', 'destination', 'room_number', 'faculty', 'department']


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
            'profile_pic_url': s.profile_pic_url,
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
