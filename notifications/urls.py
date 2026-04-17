from django.urls import path

from notifications.views import NotificationsListView

urlpatterns = [
    path('notifications', NotificationsListView.as_view(), name='notifications'),
]
