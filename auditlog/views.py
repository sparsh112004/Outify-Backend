from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from accounts.permissions import IsAdmin
from auditlog.models import Log
from auditlog.serializers import LogSerializer


class LogsListView(APIView):
    permission_classes = [IsAuthenticated, IsAdmin]

    def get(self, request):
        qs = Log.objects.all().order_by('-created_at')
        return Response(LogSerializer(qs, many=True).data)
