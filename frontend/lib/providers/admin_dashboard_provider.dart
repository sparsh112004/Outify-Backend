import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/admin_stats.dart';
import '../services/api_service.dart';

class AdminDashboardState {
  final bool isLoading;
  final AdminDashboardStats stats;
  final String? error;

  const AdminDashboardState({
    required this.isLoading,
    required this.stats,
    this.error,
  });

  factory AdminDashboardState.initial() => AdminDashboardState(
        isLoading: false,
        stats: AdminDashboardStats.empty(),
      );

  AdminDashboardState copyWith({
    bool? isLoading,
    AdminDashboardStats? stats,
    String? error,
  }) {
    return AdminDashboardState(
      isLoading: isLoading ?? this.isLoading,
      stats: stats ?? this.stats,
      error: error,
    );
  }
}

class AdminDashboardNotifier extends StateNotifier<AdminDashboardState> {
  AdminDashboardNotifier() : super(AdminDashboardState.initial());

  Future<void> fetchStats() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await ApiService.dio.get('admin/dashboard/stats/');
      final stats = AdminDashboardStats.fromJson(res.data as Map<String, dynamic>);
      state = state.copyWith(isLoading: false, stats: stats);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final adminDashboardProvider =
    StateNotifierProvider<AdminDashboardNotifier, AdminDashboardState>(
        (ref) => AdminDashboardNotifier());
