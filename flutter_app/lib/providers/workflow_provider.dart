import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../models/workflow_model.dart';

class WorkflowNotifier extends StateNotifier<AsyncValue<List<WorkflowModel>>> {
  WorkflowNotifier() : super(const AsyncValue.loading()) {
    getFlows();
  }

  Future<void> getFlows() async {
    state = const AsyncValue.loading();
    try {
      final response = await apiService.get('/workflow');
      final flows = (response as List).map((f) => WorkflowModel.fromJson(f)).toList();
      state = AsyncValue.data(flows);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final workflowProvider = StateNotifierProvider<WorkflowNotifier, AsyncValue<List<WorkflowModel>>>((ref) {
  return WorkflowNotifier();
});
