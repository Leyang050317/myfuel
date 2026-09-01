class UserModel {

  final String id;

  final String fullName;

  final String username;

  final String email;

  final String phoneNumber;

  final String icNumber;

  final String password;

  final bool emailVerified;

  final DateTime createdAt;

  final DateTime updatedAt;

  const UserModel({
    this.id = '',
    required this.fullName,
    required this.username,
    required this.email,
    required this.phoneNumber,
    required this.icNumber,
    required this.password,
    this.emailVerified = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      fullName: json['full_name'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      icNumber: json['ic_number'] ?? '',
      password: '',
      emailVerified: json['email_verified'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'username': username,
      'email': email,
      'phone_number': phoneNumber,
      'ic_number': icNumber,
      'email_verified': emailVerified,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
