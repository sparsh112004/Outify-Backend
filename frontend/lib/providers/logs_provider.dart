import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/system_log.dart';
import '../services/api_service.dart';

class LogsState {
  final bool isLoading;
  final List<SystemLog> logs;
  final String? error;

  const LogsState({
    required this.isLoading,
    required this.logs,
    this.error,
  });

  factory LogsState.initial() => const LogsState(isLoading: false, logs: []);

  LogsState copyWith({
    bool? isLoading,
    List<SystemLog>? logs,
    String? error,
  }) {
    return LogsState(
      isLoading: isLoading ?? this.isLoading,
      logs: logs ?? this.logs,
      error: error,
    );
  }
}

class LogsNotifier extends StateNotifier<LogsState> {
  LogsNotifier() : super(LogsState.initial());

  Future<void> fetchLogs() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await ApiService.dio.get('logs/');
      final list = (res.data as List).cast<Map<String, dynamic>>();
      final logs = list.map(SystemLog.fromJson).toList();
      state = state.copyWith(isLoading: false, logs: logs);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final logsProvider =
    StateNotifierProvider<LogsNotifier, LogsState>((ref) => LogsNotifier());
