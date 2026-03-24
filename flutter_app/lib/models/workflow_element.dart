class WorkflowElement {
  final String id;
  final String kind; // field, system, header, address, divider
  final String? label;
  final String type; // text, number, date, textarea, select, checkbox
  final bool required;
  final bool visible;
  final List<String> options; // For select/dropdown
  final String? sysKey; // For system fields
  final String? content; // For header/address
  final String? imageUrl; // For seals and header images
  
  // Canvas positioning
  final double x;
  final double y;
  final double w;
  final double h;

  WorkflowElement({
    required this.id,
    this.kind = 'field',
    this.label,
    this.type = 'text',
    this.required = false,
    this.visible = true,
    this.options = const [],
    this.sysKey,
    this.content,
    this.imageUrl,
    this.x = 20,
    this.y = 20,
    this.w = 200,
    this.h = 30,
  });

  factory WorkflowElement.fromJson(Map<String, dynamic> json) {
    return WorkflowElement(
      id: json['id'] ?? '',
      kind: json['kind'] ?? 'field',
      label: json['label'],
      type: json['type'] ?? 'text',
      required: json['required'] ?? false,
      visible: json['visible'] ?? true,
      options: json['options'] != null ? List<String>.from(json['options']) : [],
      sysKey: json['sysKey'],
      content: json['content'],
      imageUrl: json['imageUrl'],
      x: (json['x'] ?? 20).toDouble(),
      y: (json['y'] ?? 20).toDouble(),
      w: (json['w'] ?? 200).toDouble(),
      h: (json['h'] ?? 30).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind,
    'label': label,
    'type': type,
    'required': required,
    'visible': visible,
    'options': options,
    'sysKey': sysKey,
    'content': content,
    'imageUrl': imageUrl,
    'x': x,
    'y': y,
    'w': w,
    'h': h,
  };

  WorkflowElement copyWith({
    String? id,
    String? kind,
    String? label,
    String? type,
    bool? required,
    bool? visible,
    List<String>? options,
    String? sysKey,
    String? content,
    String? imageUrl,
    double? x,
    double? y,
    double? w,
    double? h,
  }) {
    return WorkflowElement(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      label: label ?? this.label,
      type: type ?? this.type,
      required: required ?? this.required,
      visible: visible ?? this.visible,
      options: options ?? this.options,
      sysKey: sysKey ?? this.sysKey,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      x: x ?? this.x,
      y: y ?? this.y,
      w: w ?? this.w,
      h: h ?? this.h,
    );
  }
}
