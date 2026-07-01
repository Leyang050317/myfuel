import '../models/user_model.dart';

/// Defines the authentication operations available in the application.
///
/// This is an abstract repository (contract).
/// Different implementations (Hive, Firebase, REST API)
/// can implement these methods without affecting the UI.
abstract class AuthRepository {
  /// Registers a new user.
  Future<void> register(UserModel user);

  /// Attempts to log a user into the application.
  Future<UserModel?> login({
    required String usernameOrEmail,
    required String password,
  });

  /// Logs out the currently signed-in user.
  Future<void> logout();

  /// Checks whether a username already exists.
  Future<bool> usernameExists(String username);

  /// Checks whether an email already exists.
  Future<bool> emailExists(String email);

  /// Sends a password reset request.
  Future<void> requestPasswordReset(String email);

  /// Updates the user's password.
  Future<void> updatePassword({
    required String email,
    required String newPassword,
  });

  /// Retrieves a user by their ID.
  Future<UserModel?> getUserById(String id);
  /// Sends an email verification to the currently signed-in user.
  Future<void> sendEmailVerification();
  /// Reloads the current user and checks whether their email is verified.
  Future<bool> isEmailVerified();

}