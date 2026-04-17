import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/department.dart';
import '../services/api_service.dart';

class DepartmentState {
  final bool isLoading;
  final List<Department> departments;
  final String? error;

  const DepartmentState({
    required this.isLoading,
    required this.departments,
    this.error,
  });

  factory DepartmentState.initial() => const DepartmentState(isLoading: false, departments: []);

  DepartmentState copyWith({bool? isLoading, List<Department>? departments, String? error}) {
    return DepartmentState(
      isLoading: isLoading ?? this.isLoading,
      departments: departments ?? this.departments,
      error: error,
    );
  }
}

class DepartmentNotifier extends StateNotifier<DepartmentState> {
  DepartmentNotifier() : super(DepartmentState.initial());

  Future<void> fetchDepartments() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await ApiService.dio.get('/departments');
      final list = (res.data as List).cast<Map<String, dynamic>>();
      final depts = list.map(Department.fromJson).toList();
      state = state.copyWith(isLoading: false, departments: depts);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createDepartment(String name) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ApiService.dio.post('/admin/departments', data: {'name': name});
      await fetchDepartments();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteDepartment(int id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ApiService.dio.delete('/admin/departments/$id');
      await fetchDepartments();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateDepartment(int id, String name) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ApiService.dio.patch('/admin/departments/$id', data: {'name': name});
      await fetchDepartments();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final departmentProvider = StateNotifierProvider<DepartmentNotifier, DepartmentState>((ref) => DepartmentNotifier());
