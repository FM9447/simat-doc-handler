import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/app_constants.dart';

class ApiService {
  final _storage = const FlutterSecureStorage();
  
  /// Callback triggered when a 401 Unauthorized response is received.
  /// Typically used to log the user out and clear session data.
  void Function()? onUnauthorized;

  Future<Map<String, String>> _getHeaders({bool includeContentType = false}) async {
    try {
      final token = await _storage.read(key: AppConstants.tokenKey);
      return {
        if (includeContentType) 'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
    } catch (e) {
      debugPrint('⚠️ [API] Failed to read token from storage: $e');
      return {
        if (includeContentType) 'Content-Type': 'application/json',
      };
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}$endpoint'),
      headers: await _getHeaders(includeContentType: true),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<dynamic> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}$endpoint'),
      headers: await _getHeaders(includeContentType: false),
    );
    return _handleResponse(response);
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse('${AppConstants.baseUrl}$endpoint'),
      headers: await _getHeaders(includeContentType: true),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<dynamic> delete(String endpoint) async {
    final response = await http.delete(
      Uri.parse('${AppConstants.baseUrl}$endpoint'),
      headers: await _getHeaders(includeContentType: false),
    );
    return _handleResponse(response);
  }

  Future<dynamic> multipartPost(String endpoint, Map<String, String> fields,
      {required String fileField,
      File? file,
      Uint8List? bytes,
      String? fileName}) async {
    var request = http.MultipartRequest(
        'POST', Uri.parse('${AppConstants.baseUrl}$endpoint'));
    request.headers.addAll(await _getHeaders(includeContentType: false));

    fields.forEach((key, value) {
      request.fields[key] = value;
    });

    if (bytes != null && fileName != null) {
      request.files.add(
          http.MultipartFile.fromBytes(fileField, bytes, filename: fileName));
    } else if (file != null) {
      request.files
          .add(await http.MultipartFile.fromPath(fileField, file.path));
    }

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      try {
        return jsonDecode(response.body);
      } catch (e) {
        debugPrint('⚠️ [API] JSON Decode failed: ${response.body}');
        return response.body; // Return raw body if not JSON
      }
    } else {
      if (response.statusCode == 401) {
        onUnauthorized?.call();
      }
      try {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'API Error (${response.statusCode})');
      } catch (_) {
        throw Exception('API Error (${response.statusCode}): ${response.body}');
      }
    }
  }
}

final apiService = ApiService();

