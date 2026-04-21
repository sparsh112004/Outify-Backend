import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user.dart';
import '../services/api_service.dart';
import '../services/local_storage.dart';

class AuthState {
  final bool isLoading;
  final AppUser? user;
  final String? error;

  const AuthState({required this.isLoading, required this.user, this.error});

  factory AuthState.initial() => const AuthState(isLoading: false, user: null);

  AuthState copyWith({bool? isLoading, AppUser? user, String? error}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState.initial()) {
    state = state.copyWith(user: LocalStorage.user);
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      print('DEBUG: Attempting login for $email');
      final res = await ApiService.dio.post('auth/login/', data: {'email': email, 'password': password});
      print('DEBUG: Login response received: ${res.statusCode}');
      final data = res.data as Map<String, dynamic>;
      final user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
      
      // PERSIST FIRST to ensure subsequent API calls in _RoleRouter have the token
      await LocalStorage.setAuth(
        access: data['access'] as String,
        refresh: data['refresh'] as String,
        user: user,
      );
      
      // Trigger a small delay to ensure Hive has finished writing (Flutter Web specific optimization)
      await Future.delayed(const Duration(milliseconds: 100));

      // Then update state to trigger UI transition
      state = state.copyWith(isLoading: false, user: user);
      
      print('DEBUG: Login successful for ${user.email}, state updated');
    } catch (e) {
      print('DEBUG: Login error: $e');
      state = state.copyWith(isLoading: false, error: _parseError(e));
    }
  }

  String _parseError(dynamic e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        if (data.containsKey('non_field_errors') && data['non_field_errors'] is List) {
          return (data['non_field_errors'] as List).join(', ');
        }
        if (data.containsKey('detail')) {
          return data['detail'].toString();
        }
        if (data.containsKey('error')) {
          return data['error'].toString();
        }
        // Handle field-specific errors (e.g., {"email": ["message"]})
        final fields = data.keys.where((k) => data[k] is List).toList();
        if (fields.isNotEmpty) {
          final firstField = fields.first;
          final messages = data[firstField] as List;
          return '$firstField: ${messages.join(", ")}';
        }
      }
      return e.message ?? e.toString();
    }
    return e.toString();
  }

  Future<void> registerStudent({required String name, required String email, required String password, String? collegeId, String? department, String? gender}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await ApiService.dio.post('auth/register/', data: {
        'name': name,
        'email': email,
        'password': password,
        'college_id': collegeId,
        'department': department,
        'gender': gender,
      });
      final data = res.data as Map<String, dynamic>;
      final user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
      await LocalStorage.setAuth(
        access: data['access'] as String,
        refresh: data['refresh'] as String,
        user: user,
      );
      state = state.copyWith(isLoading: false, user: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
    }
  }

  Future<void> logout() async {
    await LocalStorage.clearAuth();
    state = AuthState.initial();
  }

  Future<void> updateProfile({String? department, String? roomNumber, String? gender}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = <String, dynamic>{};
      if (department != null) data['department'] = department;
      if (roomNumber != null) data['room_number'] = roomNumber;
      if (gender != null) data['gender'] = gender;
      
      final res = await ApiService.dio.patch('auth/me/', data: data);
      final user = AppUser.fromJson(res.data as Map<String, dynamic>);
      
      // Update local storage to persist the updated user.
      await LocalStorage.setAuth(
        access: LocalStorage.accessToken ?? '',
        refresh: LocalStorage.refreshToken ?? '',
        user: user,
      );
      
      state = state.copyWith(isLoading: false, user: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      throw e; // Rethrow to allow UI to handle
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
