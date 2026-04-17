from django.urls import path

from accounts.views import (
    AdminCreateUserView,
    AdminUserListView,
    FacultyListView,
    FcmTokenView,
    LoginView,
    MeView,
    RegisterView,
    RegisterView,
    AdminUpdateUserView,
    DepartmentListView,
    AdminDepartmentView,
)

urlpatterns = [
    path('auth/register/', RegisterView.as_view(), name='register'),
    path('auth/login/', LoginView.as_view(), name='login'),
    path('auth/fcm-token/', FcmTokenView.as_view(), name='fcm-token'),
    path('auth/me/', MeView.as_view(), name='me'),
    path('users/faculties', FacultyListView.as_view(), name='faculty-list'),
    path('admin/users', AdminUserListView.as_view(), name='admin-user-list'),
    path('admin/users/create', AdminCreateUserView.as_view(), name='admin-user-create'),
    path('admin/users/<int:pk>', AdminUpdateUserView.as_view(), name='admin-user-update'),
    path('departments', DepartmentListView.as_view(), name='department-list'),
    path('admin/departments', AdminDepartmentView.as_view(), name='admin-department-create'),
    path('admin/departments/<int:pk>', AdminDepartmentView.as_view(), name='admin-department-update'),
]
