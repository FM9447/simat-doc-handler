import 'approval_model.dart';

enum DocumentStatus {
  pending,
  approvedL1,
  approvedL2,
  officePending,
  partiallyApproved,
  finalApproved,
  rejected
}

enum PriorityLevel { low, medium, high, urgent }

class DocumentModel {
  final String id;
  final dynamic studentId;
  final String title;
  final String description;
  final String category;
  final PriorityLevel priority;
  final DocumentStatus status;
  final String? fileUrl;
  final String? rejectionReason;
  final List<String> workflow;
  final List<ApprovalModel> approvals;
  final Map<String, String>? formData;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DocumentModel({
    required this.id,
    required this.studentId,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    this.status = DocumentStatus.pending,
    this.fileUrl,
    this.rejectionReason,
    this.workflow = const [],
    this.approvals = const [],
    this.formData,
    this.createdAt,
    this.updatedAt,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['_id'] ?? json['id'] ?? '',
      studentId: json['studentId'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      priority: _parsePriority(json['priority']),
      status: _parseStatus(json['status']),
      fileUrl: json['fileUrl'],
      rejectionReason: json['rejectionReason'],
      workflow: json['workflow'] != null ? List<String>.from(json['workflow']) : [],
      approvals: json['approvals'] != null 
          ? (json['approvals'] as List).map((a) => ApprovalModel.fromJson(a)).toList() 
          : [],
      formData: json['formData'] != null ? Map<String, String>.from(json['formData']) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  static PriorityLevel _parsePriority(dynamic p) {
    if (p == 'medium') return PriorityLevel.medium;
    if (p == 'high') return PriorityLevel.high;
    if (p == 'urgent') return PriorityLevel.urgent;
    return PriorityLevel.low;
  }

  static DocumentStatus _parseStatus(dynamic s) {
    switch (s) {
      case 'approved_l1': return DocumentStatus.approvedL1;
      case 'approved_l2': return DocumentStatus.approvedL2;
      case 'office_pending': return DocumentStatus.officePending;
      case 'partially_approved': return DocumentStatus.partiallyApproved;
      case 'final_approved': return DocumentStatus.finalApproved;
      case 'rejected': return DocumentStatus.rejected;
      default: return DocumentStatus.pending;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'title': title,
      'description': description,
      'category': category,
      'priority': priority.name,
      'status': _statusToString(status),
      'fileUrl': fileUrl,
      'rejectionReason': rejectionReason,
      'workflow': workflow,
      'approvals': approvals.map((a) => a.toJson()).toList(),
      'formData': formData,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  DocumentModel copyWith({
    String? id,
    dynamic studentId,
    String? title,
    String? description,
    String? category,
    PriorityLevel? priority,
    DocumentStatus? status,
    String? fileUrl,
    String? rejectionReason,
    List<String>? workflow,
    List<ApprovalModel>? approvals,
    Map<String, String>? formData,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      fileUrl: fileUrl ?? this.fileUrl,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      workflow: workflow ?? this.workflow,
      approvals: approvals ?? this.approvals,
      formData: formData ?? this.formData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static String _statusToString(DocumentStatus s) {
    switch (s) {
      case DocumentStatus.approvedL1: return 'approved_l1';
      case DocumentStatus.approvedL2: return 'approved_l2';
      case DocumentStatus.officePending: return 'office_pending';
      case DocumentStatus.partiallyApproved: return 'partially_approved';
      case DocumentStatus.finalApproved: return 'final_approved';
      case DocumentStatus.rejected: return 'rejected';
      default: return 'pending';
    }
  }
}
