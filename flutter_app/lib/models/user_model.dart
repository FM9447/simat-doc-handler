class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? registerNo;
  final String? dept;
  final String? signatureUrl;
  final String? token;
  final bool isApproved;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.registerNo,
    this.dept,
    this.signatureUrl,
    this.token,
    this.isApproved = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'student',
      registerNo: json['registerNo'],
      dept: json['dept'],
      signatureUrl: json['signatureUrl'],
      token: json['token'],
      isApproved: json['isApproved'] ?? false,
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
      'signatureUrl': signatureUrl,
      'token': token,
      'isApproved': isApproved,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? registerNo,
    String? dept,
    String? signatureUrl,
    String? token,
    bool? isApproved,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      registerNo: registerNo ?? this.registerNo,
      dept: dept ?? this.dept,
      signatureUrl: signatureUrl ?? this.signatureUrl,
      token: token ?? this.token,
      isApproved: isApproved ?? this.isApproved,
    );
  }
}
