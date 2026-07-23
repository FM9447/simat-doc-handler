class DutyCategoryModel {
  final String id;
  final String name;
  final String code;
  final String description;
  final Map<String, dynamic>? facultyInCharge;
  final bool isActive;

  DutyCategoryModel({
    required this.id,
    required this.name,
    required this.code,
    this.description = '',
    this.facultyInCharge,
    this.isActive = true,
  });

  factory DutyCategoryModel.fromJson(Map<String, dynamic> json) {
    return DutyCategoryModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      description: json['description'] ?? '',
      facultyInCharge: json['facultyInChargeId'] is Map<String, dynamic>
          ? json['facultyInChargeId'] as Map<String, dynamic>
          : null,
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'description': description,
    'facultyInChargeId': facultyInCharge?['_id'] ?? facultyInCharge?['id'],
    'isActive': isActive,
  };
}
