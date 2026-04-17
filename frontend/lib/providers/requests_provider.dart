import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/outing_request.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class RequestsState {
  final bool isLoading;
  final List<OutingRequest> items;
  final List<AppUser> faculties;
  final OutingRequest? currentRequest;
  final String? error;

  const RequestsState({
    required this.isLoading,
    required this.items,
    this.faculties = const [],
    this.currentRequest,
    this.error,
  });

  factory RequestsState.initial() => const RequestsState(isLoading: false, items: []);

  RequestsState copyWith({
    bool? isLoading,
    List<OutingRequest>? items,
    List<AppUser>? faculties,
    OutingRequest? currentRequest,
    String? error,
    bool clearError = false,
    bool clearCurrentRequest = false,
  }) {
    return RequestsState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      faculties: faculties ?? this.faculties,
      currentRequest: clearCurrentRequest ? null : (currentRequest ?? this.currentRequest),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class RequestsNotifier extends StateNotifier<RequestsState> {
  RequestsNotifier() : super(RequestsState.initial());

  Future<OutingRequest?> fetchRequestDetails(int requestId) async {
    state = state.copyWith(isLoading: true, clearError: true, clearCurrentRequest: true);
    try {
      final res = await ApiService.dio.get('/requests/$requestId');
      print('fetchRequestDetails: Successfully got data for ID $requestId');
      final outing = OutingRequest.fromJson(res.data as Map<String, dynamic>);
      state = state.copyWith(isLoading: false, currentRequest: outing);
      return outing;
    } catch (e, st) {
      state = state.copyWith(isLoading: false, error: 'Fetch Error: $e');
      print('fetchRequestDetails ERROR: $e\n$st');
      return null;
    }
  }

  Future<void> fetchStudentRequests() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await ApiService.dio.get('/requests/student');
      final list = (res.data as List).cast<Map<String, dynamic>>();
      final items = list.map(OutingRequest.fromJson).toList();
      state = state.copyWith(isLoading: false, items: items);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchFaculties(String? department) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await ApiService.dio.get('/users/faculties', queryParameters: {
        if (department != null && department.isNotEmpty) 'department': department,
      });
      final list = (res.data as List).cast<Map<String, dynamic>>();
      final faculties = list.map(AppUser.fromJson).toList();
      state = state.copyWith(isLoading: false, faculties: faculties);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createRequest({
    required String reason,
    required DateTime departure,
    required DateTime expectedReturn,
    required int facultyId,
    String? department,
    String? destination,
    String? roomNumber,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = <String, dynamic>{
        'reason': reason,
        'departure_datetime': departure.toIso8601String(),
        'expected_return_datetime': expectedReturn.toIso8601String(),
        'destination': destination,
        'faculty': facultyId,
        'department': department,
      };
      if (roomNumber != null) {
        data['room_number'] = roomNumber;
      }
      await ApiService.dio.post('/requests', data: data);
      await fetchStudentRequests();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchFacultyPending() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await ApiService.dio.get('/requests/faculty/pending');
      final list = (res.data as List).cast<Map<String, dynamic>>();
      final items = list.map(OutingRequest.fromJson).toList();
      state = state.copyWith(isLoading: false, items: items);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> facultyDecide({required int requestId, required String decision, String? remarks}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ApiService.dio.post('/requests/faculty/$requestId/decide', data: {
        'decision': decision,
        'remarks': remarks,
      });
      await fetchFacultyPending();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchWardenPending() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await ApiService.dio.get('/requests/warden/pending');
      final list = (res.data as List).cast<Map<String, dynamic>>();
      final items = list.map(OutingRequest.fromJson).toList();
      state = state.copyWith(isLoading: false, items: items);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> wardenDecide({
    required int requestId,
    required String decision,
    required String roomNumber,
    required String roomDetails,
    String? remarks,
    bool emailParent = false,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ApiService.dio.post('/requests/warden/$requestId/decide', data: {
        'decision': decision,
        'room_number': roomNumber,
        'room_details': roomDetails,
        'remarks': remarks,
        'email_parent': emailParent,
      });
      await fetchWardenPending();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchSecurityToday() async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await ApiService.dio.get('/requests/security/today');
      final list = (res.data as List).cast<Map<String, dynamic>>();
      final items = list.map(OutingRequest.fromJson).toList();
      state = state.copyWith(isLoading: false, items: items);
    } catch (e) {
      // Don't overwrite an existing error if this background poll fails
      state = state.copyWith(isLoading: false);
      print('fetchSecurityToday ERROR: $e');
    }
  }

  Future<OutingRequest?> findActiveRequest(int userId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await ApiService.dio.get('/requests/security/lookup/$userId/');
      final outing = OutingRequest.fromJson(res.data as Map<String, dynamic>);
      state = state.copyWith(isLoading: false);
      return outing;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'No active request found for this student. ($e)');
      return null;
    }
  }

  Future<void> securityVerify({required int requestId, required String action}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ApiService.dio.post('/requests/security/$requestId/verify', data: {
        'action': action,
      });
      await fetchSecurityToday();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final requestsProvider = StateNotifierProvider<RequestsNotifier, RequestsState>((ref) => RequestsNotifier());
