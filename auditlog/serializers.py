from rest_framework import serializers

from auditlog.models import Log


class LogSerializer(serializers.ModelSerializer):
    class Meta:
        model = Log
        fields = ['id', 'user', 'action', 'details', 'created_at']
