import 'dart:convert';
import 'dart:typed_data';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../core/constants/app_constants.dart';

part 'auth_provider.g.dart';

@riverpod
class Auth extends _$Auth {
  final _storage = const FlutterSecureStorage();

  @override
  FutureOr<UserModel?> build() async {
    final userData = await _storage.read(key: AppConstants.userKey);
    if (userData != null) {
      return UserModel.fromJson(jsonDecode(userData));
    }
    return null;
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final response = await apiService.post('/auth/login', {
        'email': email,
        'password': password,
      });

      final user = UserModel.fromJson(response);
      await _storage.write(key: AppConstants.tokenKey, value: user.token);
      await _storage.write(key: AppConstants.userKey, value: jsonEncode(user.toJson()));
      
      state = AsyncValue.data(user);
    } catch (e, st) {
      print('DEBUG: Login Error caught in provider: $e');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> register(Map<String, dynamic> userData) async {
    state = const AsyncValue.loading();
    try {
      final response = await apiService.post('/auth/register', userData);

      final user = UserModel.fromJson(response);
      await _storage.write(key: AppConstants.tokenKey, value: user.token);
      await _storage.write(key: AppConstants.userKey, value: jsonEncode(user.toJson()));
      
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: AppConstants.tokenKey);
    await _storage.delete(key: AppConstants.userKey);
    state = const AsyncValue.data(null);
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    try {
      await apiService.put('/auth/password', {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> uploadSignature(Uint8List bytes, String fileName) async {
    try {
      final response = await apiService.multipartPost(
        '/auth/signature',
        {},
        fileField: 'signature',
        bytes: bytes,
        fileName: fileName,
      );

      final signatureUrl = response['signatureUrl'];
      if (state.value != null) {
        final updatedUser = state.value!.copyWith(signatureUrl: signatureUrl);
        await _storage.write(key: AppConstants.userKey, value: jsonEncode(updatedUser.toJson()));
        state = AsyncValue.data(updatedUser);
      }
    } catch (e) {
      rethrow;
    }
  }
}
