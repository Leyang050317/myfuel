/// Represents a One-Time Password (OTP) used for account verification
/// and password reset.
class OTPModel {
  /// The six-digit OTP code.
  final String code;

  /// Email address associated with this OTP.
  final String email;

  /// Time when the OTP was generated.
  final DateTime createdAt;

  /// Time when the OTP expires.
  final DateTime expiresAt;

  /// Indicates whether this OTP has already been used.
  final bool isVerified;

  /// Creates a new OTPModel.
  const OTPModel({
    required this.code,
    required this.email,
    required this.createdAt,
    required this.expiresAt,
    this.isVerified = false,
  });
}