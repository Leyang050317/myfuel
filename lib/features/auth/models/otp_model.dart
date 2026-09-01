class OTPModel {
  final String code;

  final String email;

  final DateTime createdAt;

  final DateTime expiresAt;

  final bool isVerified;

  const OTPModel({
    required this.code,
    required this.email,
    required this.createdAt,
    required this.expiresAt,
    this.isVerified = false,
  });
}
