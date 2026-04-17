from rest_framework import status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken

from accounts.models import User
from accounts.permissions import IsAdmin
from accounts.serializers import (
    AdminCreateUserSerializer,
    LoginSerializer,
    RegisterSerializer,
    UpdateFcmTokenSerializer,
    UserMeSerializer,
    UserProfileUpdateSerializer,
)


class RegisterView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        refresh = RefreshToken.for_user(user)
        return Response(
            {
                'access': str(refresh.access_token),
                'refresh': str(refresh),
                'user': UserMeSerializer(user).data,
            },
            status=status.HTTP_201_CREATED,
        )


class LoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.validated_data['user']
        refresh = RefreshToken.for_user(user)
        return Response(
            {
                'access': str(refresh.access_token),
                'refresh': str(refresh),
                'user': UserMeSerializer(user).data,
            },
            status=status.HTTP_200_OK,
        )


class FcmTokenView(APIView):
    def post(self, request):
        serializer = UpdateFcmTokenSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        request.user.fcm_token = serializer.validated_data['fcm_token']
        request.user.save(update_fields=['fcm_token'])
        return Response({'status': 'ok'}, status=status.HTTP_200_OK)


class MeView(APIView):
    def get(self, request):
        return Response(UserMeSerializer(request.user).data, status=status.HTTP_200_OK)

    def patch(self, request):
        serializer = UserProfileUpdateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = request.user
        if 'department' in serializer.validated_data:
            dept_name = serializer.validated_data['department']
            if dept_name:
                from accounts.models import Department
                dept, _ = Department.objects.get_or_create(name=dept_name)
                user.department = dept
            else:
                user.department = None
        if 'room_number' in serializer.validated_data:
            user.room_number = serializer.validated_data['room_number']
        if 'gender' in serializer.validated_data:
            user.gender = serializer.validated_data['gender']
        user.save(update_fields=['department', 'room_number', 'gender'])
        return Response(UserMeSerializer(user).data, status=status.HTTP_200_OK)


class FacultyListView(APIView):
    def get(self, request):
        dept = request.query_params.get('department')
        qs = User.objects.filter(role=User.Role.FACULTY)
        if dept:
            qs = qs.filter(department__name__iexact=dept)
        return Response(UserMeSerializer(qs, many=True).data, status=status.HTTP_200_OK)


class DepartmentListView(APIView):
    def get(self, request):
        from accounts.models import Department
        depts = Department.objects.all().order_by('name')
        return Response([{'id': d.id, 'name': d.name} for d in depts], status=status.HTTP_200_OK)

# ─── Admin Views ─────────────────────────────────────────────

class AdminUserListView(APIView):
    permission_classes = [IsAuthenticated, IsAdmin]

    def get(self, request):
        role_filter = request.query_params.get('role')
        qs = User.objects.all().order_by('-created_at')
        if role_filter:
            qs = qs.filter(role=role_filter)
        return Response(UserMeSerializer(qs, many=True).data, status=status.HTTP_200_OK)


class AdminCreateUserView(APIView):
    permission_classes = [IsAuthenticated, IsAdmin]

    def post(self, request):
        serializer = AdminCreateUserSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        d = serializer.validated_data
        dept_name = d.get('department', '')
        dept = None
        if dept_name:
            from accounts.models import Department
            dept, _ = Department.objects.get_or_create(name=dept_name)

        user = User.objects.create_user(
            email=d['email'],
            password=d['password'],
            name=d['name'],
            role=d['role'],
            department=dept,
            gender=d.get('gender', ''),
        )
        return Response(UserMeSerializer(user).data, status=status.HTTP_201_CREATED)

class AdminUpdateUserView(APIView):
    permission_classes = [IsAuthenticated, IsAdmin]

    def patch(self, request, pk):
        try:
            user = User.objects.get(pk=pk)
        except User.DoesNotExist:
            return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)

        from accounts.serializers import AdminUpdateUserSerializer
        serializer = AdminUpdateUserSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        d = serializer.validated_data
        
        updated = False
        if 'name' in d:
            user.name = d['name']
            updated = True
        if 'role' in d:
            user.role = d['role']
            updated = True
        if 'department' in d:
            dept_name = d['department']
            if dept_name:
                from accounts.models import Department
                dept, _ = Department.objects.get_or_create(name=dept_name)
                user.department = dept
            else:
                user.department = None
            updated = True
        if 'gender' in d:
            user.gender = d['gender']
            updated = True
            
        if 'password' in d and d['password']:
            user.set_password(d['password'])
            updated = True

        if updated:
            user.save()
            
        return Response(UserMeSerializer(user).data, status=status.HTTP_200_OK)

class AdminDepartmentView(APIView):
    permission_classes = [IsAuthenticated, IsAdmin]

    def post(self, request):
        from accounts.models import Department
        name = request.data.get('name')
        if not name:
            return Response({'error': 'Name is required'}, status=status.HTTP_400_BAD_REQUEST)
        dept, created = Department.objects.get_or_create(name=name)
        return Response({'id': dept.id, 'name': dept.name}, status=status.HTTP_201_CREATED)

    def delete(self, request, pk):
        from accounts.models import Department
        try:
            dept = Department.objects.get(pk=pk)
            dept.delete()
            return Response(status=status.HTTP_204_NO_CONTENT)
        except Department.DoesNotExist:
            return Response(status=status.HTTP_404_NOT_FOUND)

    def patch(self, request, pk):
        from accounts.models import Department
        try:
            dept = Department.objects.get(pk=pk)
            name = request.data.get('name')
            if name:
                dept.name = name
                dept.save()
            return Response({'id': dept.id, 'name': dept.name}, status=status.HTTP_200_OK)
        except Department.DoesNotExist:
            return Response(status=status.HTTP_404_NOT_FOUND)
