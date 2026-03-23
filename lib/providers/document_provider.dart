import 'dart:io' if (dart.library.html) 'package:antigravity/stubs/io_stub.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/document_model.dart';
import '../services/api_service.dart';

part 'document_provider.g.dart';

@riverpod
class DocumentList extends _$DocumentList {
  @override
  FutureOr<List<DocumentModel>> build() async {
    return _fetchDocuments();
  }

  Future<List<DocumentModel>> _fetchDocuments() async {
    final response = await apiService.get('/documents');
    return (response as List).map((doc) => DocumentModel.fromJson(doc)).toList();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final docs = await _fetchDocuments();
      state = AsyncValue.data(docs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> submitDocument({
    required String title,
    required String description,
    required String category,
    required String priority,
    Uint8List? fileBytes,
    String? fileName,
    File? file,
    Map<String, String>? formData,
    required List<String> workflow,
  }) async {
    await apiService.multipartPost(
      '/documents',
      {
        'title': title,
        'description': description,
        'category': category,
        'priority': priority.toLowerCase(),
        'workflow': jsonEncode(workflow), 
        if (formData != null) 'formData': jsonEncode(formData),
      },
      fileField: 'file',
      file: file,
      bytes: fileBytes,
      fileName: fileName,
    );
    await refresh();
  }

  Future<void> approveDocument(
    String id, 
    String action, 
    String comment, {
    Uint8List? signatureBytes, 
    String? signatureName, 
    File? signatureFile,
    String? signatureUrl,
  }) async {
    if (signatureBytes != null || signatureFile != null) {
      await apiService.multipartPost(
        '/documents/$id/approve',
        {
          'action': action,
          'comment': comment,
        },
        fileField: 'signature',
        file: signatureFile,
        bytes: signatureBytes,
        fileName: signatureName,
      );
    } else {
      await apiService.post('/documents/$id/approve', {
        'action': action,
        'comment': comment,
        if (signatureUrl != null) 'signatureUrl': signatureUrl,
      });
    }
    await refresh();
  }
}
