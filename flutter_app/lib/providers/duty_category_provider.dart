import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/duty_category_model.dart';
import '../services/api_service.dart';

part 'duty_category_provider.g.dart';

@riverpod
class DutyCategoryNotifier extends _$DutyCategoryNotifier {
  @override
  FutureOr<List<DutyCategoryModel>> build() async {
    return _fetchCategories();
  }

  Future<List<DutyCategoryModel>> _fetchCategories() async {
    final response = await apiService.get('/duty-categories');
    return (response as List).map((cat) => DutyCategoryModel.fromJson(cat)).toList();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final cats = await _fetchCategories();
      state = AsyncValue.data(cats);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createCategory({
    required String name,
    required String code,
    String? description,
    String? facultyInChargeId,
  }) async {
    await apiService.post('/duty-categories', {
      'name': name,
      'code': code,
      if (description != null) 'description': description,
      if (facultyInChargeId != null) 'facultyInChargeId': facultyInChargeId,
    });
    await refresh();
  }

  Future<void> updateCategory({
    required String id,
    String? name,
    String? description,
    String? facultyInChargeId,
    bool? isActive,
  }) async {
    await apiService.put('/duty-categories/$id', {
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      'facultyInChargeId': facultyInChargeId,
      if (isActive != null) 'isActive': isActive,
    });
    await refresh();
  }

  Future<void> deleteCategory(String id) async {
    await apiService.delete('/duty-categories/$id');
    await refresh();
  }
}
