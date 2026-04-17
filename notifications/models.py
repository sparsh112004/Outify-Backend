from django.conf import settings
from django.db import models


class Notification(models.Model):
    class Type(models.TextChoices):
        EMAIL = 'email'
        PUSH = 'push'

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    type = models.CharField(max_length=20, choices=Type.choices)
    title = models.CharField(max_length=255, null=True, blank=True)
    body = models.TextField(null=True, blank=True)
    sent_at = models.DateTimeField(auto_now_add=True)
    status = models.CharField(max_length=20, default='sent')

    class Meta:
        indexes = [
            models.Index(fields=['user', 'sent_at']),
            models.Index(fields=['type', 'sent_at']),
        ]

    def __str__(self):
        return f'Notification#{self.id} {self.type} user={self.user_id}'
