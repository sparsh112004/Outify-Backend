from django.urls import path

from outings.views import (
    FacultyDecideView,
    FacultyPendingListView,
    OutingDetailView,
    SecurityTodayListView,
    SecurityVerifyView,
    StudentCancelOutingView,
    StudentCreateOutingView,
    StudentOutingsListView,
    WardenDecideView,
    WardenPendingListView,
    ParentDecideView,
    SecurityScanLookupView,
)

urlpatterns = [
    # Specific named routes MUST come before generic <int:pk> routes
    path('requests/student/', StudentOutingsListView.as_view(), name='student-list'),

    path('requests/faculty/pending/', FacultyPendingListView.as_view(), name='faculty-pending'),
    path('requests/faculty/<int:pk>/decide/', FacultyDecideView.as_view(), name='faculty-decide'),

    path('requests/warden/pending/', WardenPendingListView.as_view(), name='warden-pending'),
    path('requests/warden/<int:pk>/decide/', WardenDecideView.as_view(), name='warden-decide'),

    path('requests/security/today/', SecurityTodayListView.as_view(), name='security-today'),
    path('requests/security/lookup/<int:user_id>/', SecurityScanLookupView.as_view(), name='security-lookup'),
    path('requests/security/<int:pk>/verify/', SecurityVerifyView.as_view(), name='security-verify'),

    # Generic routes last
    path('requests/', StudentCreateOutingView.as_view(), name='student-create'),
    path('requests/<int:pk>/', OutingDetailView.as_view(), name='detail'),
    path('requests/<int:pk>/cancel/', StudentCancelOutingView.as_view(), name='student-cancel'),
    path('requests/<int:pk>/parent-<str:action>/', ParentDecideView.as_view(), name='parent-decide'),
]
