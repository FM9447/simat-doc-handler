class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? registerNo;
  final String? dept; // Legacy string
  final String? departmentId;
  final String? departmentName;
  final String? tutorId;
  final String? tutorName;
  final int? year;
  final String? division;
  final String? hodOfDeptId;
  final String? signatureUrl;
  final String? token;
  final bool isApproved;
  final String? delegatedToId;
  final String? delegatedToName;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.registerNo,
    this.dept,
    this.departmentId,
    this.departmentName,
    this.tutorId,
    this.tutorName,
    this.year,
    this.division,
    this.hodOfDeptId,
    this.signatureUrl,
    this.token,
    this.isApproved = false,
    this.delegatedToId,
    this.delegatedToName,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'student',
      registerNo: json['registerNo'],
      dept: json['dept'],
      departmentId: json['departmentId'] is Map ? json['departmentId']['_id'] : json['departmentId'],
      departmentName: json['departmentId'] is Map ? json['departmentId']['name'] : null,
      tutorId: json['tutorId'] is Map ? json['tutorId']['_id'] : json['tutorId'],
      tutorName: json['tutorId'] is Map ? json['tutorId']['name'] : null,
      year: json['year'],
      division: json['division'],
      hodOfDeptId: json['hodOfDeptId'],
      signatureUrl: json['signatureUrl'],
      token: json['token'],
      isApproved: json['isApproved'] ?? false,
      delegatedToId: json['delegatedTo'] is Map ? json['delegatedTo']['_id'] : json['delegatedTo'],
      delegatedToName: json['delegatedTo'] is Map ? json['delegatedTo']['name'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'registerNo': registerNo,
      'dept': dept,
      'departmentId': departmentId,
      'tutorId': tutorId,
      'year': year,
      'division': division,
      'hodOfDeptId': hodOfDeptId,
      'signatureUrl': signatureUrl,
      'token': token,
      'isApproved': isApproved,
      'delegatedTo': delegatedToId,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? registerNo,
    String? dept,
    String? departmentId,
    String? tutorId,
    int? year,
    String? division,
    String? hodOfDeptId,
    String? signatureUrl,
    String? token,
    bool? isApproved,
    String? delegatedToId,
    String? delegatedToName,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      registerNo: registerNo ?? this.registerNo,
      dept: dept ?? this.dept,
      departmentId: departmentId ?? this.departmentId,
      tutorId: tutorId ?? this.tutorId,
      year: year ?? this.year,
      division: division ?? this.division,
      hodOfDeptId: hodOfDeptId ?? this.hodOfDeptId,
      signatureUrl: signatureUrl ?? this.signatureUrl,
      token: token ?? this.token,
      isApproved: isApproved ?? this.isApproved,
      delegatedToId: delegatedToId ?? this.delegatedToId,
      delegatedToName: delegatedToName ?? this.delegatedToName,
    );
  }
}
