from django.urls import path

from auditlog.views import LogsListView

urlpatterns = [
    path('logs/', LogsListView.as_view(), name='logs'),
]
