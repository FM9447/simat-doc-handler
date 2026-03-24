class ApprovalModel {
  final String? id;
  final dynamic approverId;
  final String action;
  final String? comment;
  final String? signatureUrl;
  final String? role; // Added role field
  final DateTime? createdAt;

  ApprovalModel({
    this.id,
    required this.approverId,
    required this.action,
    this.comment,
    this.signatureUrl,
    this.role,
    this.createdAt,
  });

  factory ApprovalModel.fromJson(Map<String, dynamic> json) {
    return ApprovalModel(
      id: json['_id'],
      approverId: json['approverId'],
      action: json['action'] ?? '',
      comment: json['comment'],
      signatureUrl: json['signatureUrl'],
      role: json['role'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'approverId': approverId,
      'action': action,
      'comment': comment,
      'signatureUrl': signatureUrl,
      'role': role,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  ApprovalModel copyWith({
    String? id,
    dynamic approverId,
    String? action,
    String? comment,
    String? signatureUrl,
    String? role,
    DateTime? createdAt,
  }) {
    return ApprovalModel(
      id: id ?? this.id,
      approverId: approverId ?? this.approverId,
      action: action ?? this.action,
      comment: comment ?? this.comment,
      signatureUrl: signatureUrl ?? this.signatureUrl,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
