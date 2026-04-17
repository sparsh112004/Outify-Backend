import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/user.dart';
import '../utils/constants.dart';

class LocalStorage {
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(AppConstants.hiveBox);
  }

  static Box get _box => Hive.box(AppConstants.hiveBox);

  static String? get accessToken => _box.get(AppConstants.hiveKeyAccessToken) as String?;
  static String? get refreshToken => _box.get(AppConstants.hiveKeyRefreshToken) as String?;

  static AppUser? get user {
    final raw = _box.get(AppConstants.hiveKeyUser) as String?;
    if (raw == null) return null;
    return AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  static Future<void> setAuth({required String access, required String refresh, required AppUser user}) async {
    await _box.put(AppConstants.hiveKeyAccessToken, access);
    await _box.put(AppConstants.hiveKeyRefreshToken, refresh);
    await _box.put(AppConstants.hiveKeyUser, jsonEncode(user.toJson()));
  }

  static Future<void> clearAuth() async {
    await _box.delete(AppConstants.hiveKeyAccessToken);
    await _box.delete(AppConstants.hiveKeyRefreshToken);
    await _box.delete(AppConstants.hiveKeyUser);
  }
}
