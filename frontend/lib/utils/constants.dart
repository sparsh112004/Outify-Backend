import 'package:flutter/foundation.dart';

class AppConstants {
  static const String localApiUrl = 'http://localhost:8000/api/';
  static const String productionApiUrl = 'https://outify-backend-production.up.railway.app/api/';

  static String get apiBaseUrl => kReleaseMode ? productionApiUrl : localApiUrl;

  static const String hiveBox = 'app_box';
  static const String hiveKeyAccessToken = 'access_token';
  static const String hiveKeyRefreshToken = 'refresh_token';
  static const String hiveKeyUser = 'user';
}
