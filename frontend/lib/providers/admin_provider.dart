import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user.dart';
import '../services/api_service.dart';

class AdminState {
  final bool isLoading;
  final List<AppUser> users;
  final String? error;
  final String? successMessage;

  const AdminState({
    required this.isLoading,
    required this.users,
    this.error,
    this.successMessage,
  });

  factory AdminState.initial() => const AdminState(isLoading: false, users: []);

  AdminState copyWith({bool? isLoading, List<AppUser>? users, String? error, String? successMessage}) {
    return AdminState(
      isLoading: isLoading ?? this.isLoading,
      users: users ?? this.users,
      error: error,
      successMessage: successMessage,
    );
  }
}

class AdminNotifier extends StateNotifier<AdminState> {
  AdminNotifier() : super(AdminState.initial());

  Future<void> fetchUsers({String? role}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await ApiService.dio.get('/admin/users', queryParameters: {
        if (role != null && role.isNotEmpty) 'role': role,
      });
      final list = (res.data as List).cast<Map<String, dynamic>>();
      final users = list.map(AppUser.fromJson).toList();
      state = state.copyWith(isLoading: false, users: users);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
    String? department,
    String? gender,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ApiService.dio.post('/admin/users/create', data: {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        if (department != null && department.isNotEmpty) 'department': department,
        if (gender != null && gender.isNotEmpty) 'gender': gender,
      });
      state = state.copyWith(isLoading: false, successMessage: '$name created successfully!');
      await fetchUsers();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateUser(int id, {
    String? name,
    String? role,
    String? department,
    String? gender,
    String? password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ApiService.dio.patch('/admin/users/$id', data: {
        if (name != null && name.isNotEmpty) 'name': name,
        if (role != null && role.isNotEmpty) 'role': role,
        if (department != null) 'department': department,
        if (gender != null) 'gender': gender,
        if (password != null && password.isNotEmpty) 'password': password,
      });
      state = state.copyWith(isLoading: false, successMessage: 'User updated successfully!');
      await fetchUsers(); // Re-fetch to get updated data
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final adminProvider = StateNotifierProvider<AdminNotifier, AdminState>((ref) => AdminNotifier());
