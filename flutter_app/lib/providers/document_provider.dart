import 'dart:io';
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
    String? customHeading,
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
        if (customHeading != null) 'customHeading': customHeading,
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

  Future<void> updateDocument({
    required String id,
    String? title,
    String? description,
    String? customHeading,
    Map<String, dynamic>? formData,
  }) async {
    await apiService.put('/documents/$id', {
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (customHeading != null) 'customHeading': customHeading,
      if (formData != null) 'formData': formData,
    });
    await refresh();
  }
}
