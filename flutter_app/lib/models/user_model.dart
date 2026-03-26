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
    // Robust parsing for populated fields (handles both ObjectIds and populated Objects safely)
    String? parseId(dynamic val) {
      if (val is Map) return val['_id']?.toString() ?? val['id']?.toString();
      return val?.toString();
    }

    String? parseName(dynamic val) {
      if (val is Map) return val['name']?.toString();
      return null;
    }

    return UserModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'student',
      registerNo: json['registerNo']?.toString(),
      dept: json['dept']?.toString(),
      departmentId: parseId(json['departmentId']),
      departmentName: parseName(json['departmentId']),
      tutorId: parseId(json['tutorId']),
      tutorName: parseName(json['tutorId']),
      year: json['year'] is int ? json['year'] : int.tryParse(json['year']?.toString() ?? ''),
      division: json['division']?.toString(),
      hodOfDeptId: json['hodOfDeptId']?.toString(),
      signatureUrl: json['signatureUrl']?.toString(),
      token: json['token']?.toString(),
      isApproved: json['isApproved'] == true, // Handles both bool and null
      delegatedToId: parseId(json['delegatedTo']),
      delegatedToName: parseName(json['delegatedTo']),
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
