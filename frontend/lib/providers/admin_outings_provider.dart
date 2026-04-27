import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/outing_request.dart';
import '../services/api_service.dart';

class AdminOutingsState {
  final bool isLoading;
  final List<OutingRequest> outings;
  final String? error;

  const AdminOutingsState({
    required this.isLoading,
    required this.outings,
    this.error,
  });

  factory AdminOutingsState.initial() => const AdminOutingsState(isLoading: false, outings: []);

  AdminOutingsState copyWith({
    bool? isLoading,
    List<OutingRequest>? outings,
    String? error,
  }) {
    return AdminOutingsState(
      isLoading: isLoading ?? this.isLoading,
      outings: outings ?? this.outings,
      error: error,
    );
  }
}

class AdminOutingsNotifier extends StateNotifier<AdminOutingsState> {
  AdminOutingsNotifier() : super(AdminOutingsState.initial());

  Future<void> fetchOutings({String? status, String? date}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await ApiService.dio.get('admin/outings/', queryParameters: {
        if (status != null) 'status': status,
        if (date != null) 'date': date,
      });
      
      final list = (res.data as List).cast<Map<String, dynamic>>();
      final outings = list.map(OutingRequest.fromJson).toList();
      
      state = state.copyWith(isLoading: false, outings: outings);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final adminOutingsProvider =
    StateNotifierProvider<AdminOutingsNotifier, AdminOutingsState>((ref) => AdminOutingsNotifier());
