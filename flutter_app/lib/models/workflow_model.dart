import 'workflow_element.dart';

class WorkflowModel {
  final String? id;
  final String name;
  final List<String> steps;
  final bool isActive;
  final bool isFormBased;
  final List<String> requiredFields;
  final List<WorkflowElement> elements;
  final String letterTemplate;
  final String templateTo;
  final String templateClosing;
  final bool allowCustomHeading;
  final bool includeLetterhead;
  final bool includeRefDate;
  final bool includeSeal;
  final String? customHeaderUrl;
  final String? customApprovedSealUrl;
  final String? customRejectedSealUrl;

  WorkflowModel({
    this.id,
    required this.name,
    required this.steps,
    this.isActive = true,
    this.isFormBased = false,
    this.requiredFields = const [],
    this.elements = const [],
    this.letterTemplate = '',
    this.templateTo = '',
    this.templateClosing = 'Sincerely,',
    this.allowCustomHeading = false,
    this.includeLetterhead = true,
    this.includeRefDate = true,
    this.includeSeal = false,
    this.customHeaderUrl,
    this.customApprovedSealUrl,
    this.customRejectedSealUrl,
  });

  factory WorkflowModel.fromJson(Map<String, dynamic> json) {
    final stepsRaw = json['steps'];
    final steps = stepsRaw is List ? List<String>.from(stepsRaw) : <String>[];
    final requiredFieldsRaw = json['requiredFields'];
    final requiredFields = requiredFieldsRaw is List ? List<String>.from(requiredFieldsRaw) : <String>[];
    final elementsRaw = json['elements'];
    final elements = elementsRaw is List
        ? elementsRaw.map((e) => WorkflowElement.fromJson(e)).toList()
        : <WorkflowElement>[];
    return WorkflowModel(
      id: json['_id'] ?? json['id'],
      name: json['name'] ?? '',
      steps: steps,
      isActive: json['isActive'] ?? true,
      isFormBased: json['isFormBased'] ?? false,
      requiredFields: requiredFields,
      elements: elements,
      letterTemplate: json['letterTemplate'] ?? '',
      templateTo: json['templateTo'] ?? '',
      templateClosing: json['templateClosing'] ?? 'Sincerely,',
      allowCustomHeading: json['allowCustomHeading'] ?? false,
      includeLetterhead: json['includeLetterhead'] ?? true,
      includeRefDate: json['includeRefDate'] ?? true,
      includeSeal: json['includeSeal'] ?? false,
      customHeaderUrl: json['customHeaderUrl'],
      customApprovedSealUrl: json['customApprovedSealUrl'] ?? json['customSealUrl'],
      customRejectedSealUrl: json['customRejectedSealUrl'],
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'steps': steps,
    'isActive': isActive,
    'isFormBased': isFormBased,
    'requiredFields': requiredFields,
    'elements': elements.map((e) => e.toJson()).toList(),
    'letterTemplate': letterTemplate,
    'templateTo': templateTo,
    'templateClosing': templateClosing,
    'allowCustomHeading': allowCustomHeading,
    'includeLetterhead': includeLetterhead,
    'includeRefDate': includeRefDate,
    'includeSeal': includeSeal,
    'customHeaderUrl': customHeaderUrl,
    'customApprovedSealUrl': customApprovedSealUrl,
    'customRejectedSealUrl': customRejectedSealUrl,
  };

  /// Get visible form fields (kind == 'field' && visible == true for student input)
  List<WorkflowElement> get visibleFields =>
      elements.where((e) => e.kind == 'field' && e.visible).toList();

  /// Get all field labels for placeholder reference
  List<String> get fieldLabels =>
      elements.where((e) => e.kind == 'field').map((e) => e.label ?? '').where((l) => l.isNotEmpty).toList();
}
