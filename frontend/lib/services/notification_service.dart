import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  // Mock service for Web/Chrome to prevent compilation errors
  static Future<void> init() async {}
  static Future<void> scheduleReturnReminder(int requestId, DateTime returnTime) async {}
  static Future<void> cancelReminder(int requestId) async {}
}
