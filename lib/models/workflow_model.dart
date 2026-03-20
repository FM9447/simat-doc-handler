class WorkflowModel {
  final String? id;
  final String name;
  final List<String> steps;
  final bool isActive;
  final bool isFormBased;
  final List<String> requiredFields;

  WorkflowModel({
    this.id,
    required this.name,
    required this.steps,
    this.isActive = true,
    this.isFormBased = false,
    this.requiredFields = const [],
  });

  factory WorkflowModel.fromJson(Map<String, dynamic> json) {
    final stepsRaw = json['steps'];
    final steps = stepsRaw is List ? List<String>.from(stepsRaw) : <String>[];
    final requiredFieldsRaw = json['requiredFields'];
    final requiredFields = requiredFieldsRaw is List ? List<String>.from(requiredFieldsRaw) : <String>[];
    return WorkflowModel(
      id: json['_id'] ?? json['id'],
      name: json['name'] ?? '',
      steps: steps,
      isActive: json['isActive'] ?? true,
      isFormBased: json['isFormBased'] ?? false,
      requiredFields: requiredFields,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'steps': steps,
    'isActive': isActive,
    'isFormBased': isFormBased,
    'requiredFields': requiredFields,
  };
}
