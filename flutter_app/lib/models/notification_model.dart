class NotificationModel {
  final String id;
  final String message;
  final String type; // info, ok, err
  final bool read;
  final DateTime? createdAt;

  NotificationModel({
    required this.id,
    required this.message,
    this.type = 'info',
    this.read = false,
    this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? json['id'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'info',
      read: json['read'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'message': message,
    'type': type,
    'read': read,
    'createdAt': createdAt?.toIso8601String(),
  };
}
