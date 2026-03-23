import 'dart:convert';
import 'dart:io' if (dart.library.html) 'package:antigravity/stubs/io_stub.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/app_constants.dart';

class ApiService {
  final _storage = const FlutterSecureStorage();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}$endpoint'),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<dynamic> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}$endpoint'),
      headers: await _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse('${AppConstants.baseUrl}$endpoint'),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<dynamic> delete(String endpoint) async {
    final response = await http.delete(
      Uri.parse('${AppConstants.baseUrl}$endpoint'),
      headers: await _getHeaders(),
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
    request.headers.addAll(await _getHeaders());

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
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'API Error');
    }
  }
}

final apiService = ApiService();
