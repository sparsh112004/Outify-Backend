from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from accounts.permissions import IsAdmin
from notifications.models import Notification
from notifications.serializers import NotificationSerializer


class NotificationsListView(APIView):
    permission_classes = [IsAuthenticated, IsAdmin]

    def get(self, request):
        qs = Notification.objects.all().order_by('-sent_at')
        return Response(NotificationSerializer(qs, many=True).data)
