import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import '../models/workflow_model.dart';

class AdminNotifier extends StateNotifier<AsyncValue<List<UserModel>>> {
  AdminNotifier() : super(const AsyncValue.loading()) {
    getUsers();
  }

  Future<void> getUsers() async {
    state = const AsyncValue.loading();
    try {
      final List<dynamic> response = await apiService.get('/auth/users');
      final users = response.map((u) => UserModel.fromJson(u)).toList();
      state = AsyncValue.data(users);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await apiService.put('/auth/users/$userId', data);
    await getUsers();
  }

  Future<void> deleteUser(String userId) async {
    await apiService.delete('/auth/users/$userId');
    await getUsers();
  }
}

class AdminWorkflowNotifier extends StateNotifier<AsyncValue<List<WorkflowModel>>> {
  AdminWorkflowNotifier() : super(const AsyncValue.loading()) {
    getWorkflows();
  }

  Future<void> getWorkflows() async {
    state = const AsyncValue.loading();
    try {
      final List<dynamic> response = await apiService.get('/workflow');
      final flows = response.map((f) => WorkflowModel.fromJson(f)).toList();
      state = AsyncValue.data(flows);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addWorkflow(WorkflowModel workflow) async {
    await apiService.post('/workflow', workflow.toJson());
    await getWorkflows();
  }

  Future<void> updateWorkflow(String id, WorkflowModel workflow) async {
    await apiService.put('/workflow/$id', workflow.toJson());
    await getWorkflows();
  }

  Future<void> deleteWorkflow(String id) async {
    await apiService.delete('/workflow/$id');
    await getWorkflows();
  }
 
  Future<String> uploadImage(Uint8List bytes, String fileName) async {
    final response = await apiService.multipartPost(
      '/workflow/upload',
      {},
      fileField: 'file',
      bytes: bytes,
      fileName: fileName,
    );
    return response['url'];
  }
}

class AdminDepartmentNotifier extends StateNotifier<AsyncValue<List<dynamic>>> {
  AdminDepartmentNotifier() : super(const AsyncValue.loading()) {
    getDepartments();
  }

  Future<void> getDepartments() async {
    state = const AsyncValue.loading();
    try {
      final List<dynamic> response = await apiService.get('/departments');
      state = AsyncValue.data(response);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addDepartment(String name) async {
    await apiService.post('/departments', {'name': name});
    await getDepartments();
  }

  Future<void> assignHod(String deptId, String hodId) async {
    await apiService.put('/departments/$deptId/hod', {'hodId': hodId});
    await getDepartments();
  }

  Future<void> deleteDepartment(String deptId) async {
    await apiService.delete('/departments/$deptId');
    await getDepartments();
  }
}

final adminUserProvider = StateNotifierProvider<AdminNotifier, AsyncValue<List<UserModel>>>((ref) {
  return AdminNotifier();
});

final adminWorkflowProvider = StateNotifierProvider<AdminWorkflowNotifier, AsyncValue<List<WorkflowModel>>>((ref) {
  return AdminWorkflowNotifier();
});

final adminDepartmentProvider = StateNotifierProvider<AdminDepartmentNotifier, AsyncValue<List<dynamic>>>((ref) {
  return AdminDepartmentNotifier();
});
