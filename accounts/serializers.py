from django.contrib.auth import authenticate
from rest_framework import serializers

from accounts.models import Department, User


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=6)
    department = serializers.SlugRelatedField(slug_field='name', queryset=Department.objects.all(), required=False, allow_null=True)

    class Meta:
        model = User
        fields = ['id', 'name', 'email', 'password', 'college_id', 'department', 'gender', 'room_number', 'profile_pic_url']

    def create(self, validated_data):
        password = validated_data.pop('password')
        user = User.objects.create_user(password=password, role=User.Role.STUDENT, **validated_data)
        return user


class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)

    def validate(self, attrs):
        user = authenticate(username=attrs.get('email'), password=attrs.get('password'))
        if not user:
            raise serializers.ValidationError('Invalid credentials')
        if not user.is_active:
            raise serializers.ValidationError('User is inactive')
        attrs['user'] = user
        return attrs


class UserMeSerializer(serializers.ModelSerializer):
    department = serializers.SlugRelatedField(slug_field='name', read_only=True)
    
    class Meta:
        model = User
        fields = ['id', 'name', 'email', 'role', 'college_id', 'department', 'gender', 'room_number', 'fcm_token', 'profile_pic_url', 'created_at']


class UserProfileUpdateSerializer(serializers.Serializer):
    department = serializers.CharField(required=False, allow_blank=True, allow_null=True)
    room_number = serializers.CharField(required=False, allow_blank=True, allow_null=True)
    gender = serializers.ChoiceField(choices=User.Gender.choices, required=False, allow_blank=True, allow_null=True)


class UpdateFcmTokenSerializer(serializers.Serializer):
    fcm_token = serializers.CharField()


class AdminCreateUserSerializer(serializers.Serializer):
    name = serializers.CharField(max_length=100)
    email = serializers.EmailField()
    password = serializers.CharField(min_length=6)
    role = serializers.ChoiceField(choices=['faculty', 'warden', 'security'])
    department = serializers.CharField(max_length=100, required=False, allow_blank=True, allow_null=True)
    gender = serializers.ChoiceField(choices=User.Gender.choices, required=False, allow_blank=True, allow_null=True)

    def validate_email(self, value):
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError('A user with this email already exists.')
        return value

class AdminUpdateUserSerializer(serializers.Serializer):
    name = serializers.CharField(max_length=100, required=False)
    role = serializers.ChoiceField(choices=['student', 'faculty', 'warden', 'security', 'admin'], required=False)
    department = serializers.CharField(max_length=100, required=False, allow_blank=True, allow_null=True)
    gender = serializers.ChoiceField(choices=User.Gender.choices, required=False, allow_blank=True, allow_null=True)
    password = serializers.CharField(min_length=6, required=False, allow_blank=True, allow_null=True)
