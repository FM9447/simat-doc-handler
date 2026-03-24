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
  final String? customHeading;
  final String description;
  final String category;
  final String? flow; // Workflow name
  final PriorityLevel priority;
  final DocumentStatus status;
  final String? fileUrl;
  final String? studentSignatureUrl;
  final String? rejectionReason;
  final List<String> workflow;
  final Map<String, dynamic> assigned; // role -> {id, name} or String (for legacy)
  final List<ApprovalModel> approvals;
  final Map<String, dynamic>? formData;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DocumentModel({
    required this.id,
    required this.studentId,
    required this.title,
    this.customHeading,
    required this.description,
    required this.category,
    this.flow,
    required this.priority,
    this.status = DocumentStatus.pending,
    this.fileUrl,
    this.studentSignatureUrl,
    this.rejectionReason,
    this.workflow = const [],
    this.assigned = const {},
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
      customHeading: json['customHeading'],
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      flow: json['flow'],
      priority: _parsePriority(json['priority']),
      status: _parseStatus(json['status']),
      fileUrl: json['fileUrl'],
      studentSignatureUrl: json['studentSignatureUrl'],
      rejectionReason: json['rejectionReason'],
      workflow: json['workflow'] != null ? List<String>.from(json['workflow']) : [],
      assigned: json['assigned'] != null ? Map<String, dynamic>.from(json['assigned']) : {},
      approvals: json['approvals'] != null 
          ? (json['approvals'] as List).map((a) => ApprovalModel.fromJson(a)).toList() 
          : [],
      formData: json['formData'] != null ? Map<String, dynamic>.from(json['formData']) : null,
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
      'customHeading': customHeading,
      'description': description,
      'category': category,
      'flow': flow,
      'priority': priority.name,
      'status': _statusToString(status),
      'fileUrl': fileUrl,
      'studentSignatureUrl': studentSignatureUrl,
      'rejectionReason': rejectionReason,
      'workflow': workflow,
      'assigned': assigned,
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
    String? customHeading,
    String? description,
    String? category,
    String? flow,
    PriorityLevel? priority,
    DocumentStatus? status,
    String? fileUrl,
    String? studentSignatureUrl,
    String? rejectionReason,
    List<String>? workflow,
    Map<String, String>? assigned,
    List<ApprovalModel>? approvals,
    Map<String, dynamic>? formData,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      title: title ?? this.title,
      customHeading: customHeading ?? this.customHeading,
      description: description ?? this.description,
      category: category ?? this.category,
      flow: flow ?? this.flow,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      fileUrl: fileUrl ?? this.fileUrl,
      studentSignatureUrl: studentSignatureUrl ?? this.studentSignatureUrl,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      workflow: workflow ?? this.workflow,
      assigned: assigned ?? this.assigned,
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

  /// Human-readable status label matching TSX SL map
  String get statusLabel {
    switch (status) {
      case DocumentStatus.pending: return 'Pending';
      case DocumentStatus.partiallyApproved: return 'In Progress';
      case DocumentStatus.finalApproved: return 'Approved';
      case DocumentStatus.rejected: return 'Rejected';
      default: return status.name;
    }
  }
}
