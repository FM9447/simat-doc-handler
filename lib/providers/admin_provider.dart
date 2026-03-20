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

  Future<void> addWorkflow(String name, List<String> steps, {bool isFormBased = false, List<String> requiredFields = const []}) async {
    await apiService.post('/workflow', {
      'name': name, 
      'steps': steps,
      'isFormBased': isFormBased,
      'requiredFields': requiredFields,
    });
    await getWorkflows();
  }

  Future<void> updateWorkflow(String id, String name, List<String> steps, {bool? isFormBased, List<String>? requiredFields}) async {
    await apiService.put('/workflow/$id', {
      'name': name, 
      'steps': steps,
      'isFormBased': isFormBased,
      'requiredFields': requiredFields,
    });
    await getWorkflows();
  }

  Future<void> deleteWorkflow(String id) async {
    await apiService.delete('/workflow/$id');
    await getWorkflows();
  }
}

final adminUserProvider = StateNotifierProvider<AdminNotifier, AsyncValue<List<UserModel>>>((ref) {
  return AdminNotifier();
});

final adminWorkflowProvider = StateNotifierProvider<AdminWorkflowNotifier, AsyncValue<List<WorkflowModel>>>((ref) {
  return AdminWorkflowNotifier();
});
