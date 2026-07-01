/// Data model representing an authenticated user.

/// Represents a registered user in the MyFuel application.
///
/// This model stores all information related to a user's account.
/// It will later be used with Firebase Authentication and Firestore.
class UserModel {
  /// Unique user identifier.
  /// Later this will store the Firebase UID.
  final String id;

  /// User's full name.
  final String fullName;

  /// Username used for logging into the application.
  final String username;

  /// User's email address.
  final String email;

  /// User's phone number.
  final String phoneNumber;

  /// Malaysian IC (NRIC) number.
  final String icNumber;

  /// User's password.
  ///
  /// NOTE:
  /// This is temporary for development.
  /// When Firebase Authentication is integrated,
  /// passwords will NOT be stored here.
  final String password;

  /// Indicates whether the user's email has been verified.
  final bool emailVerified;

  /// Date and time when the account was created.
  final DateTime createdAt;

  /// Date and time when the account information was last updated.
  final DateTime updatedAt;

  /// Creates a new UserModel.
  const UserModel({
    required this.id,
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
}
