import '../models/user_model.dart';

abstract class AuthRepository {
  Future<void> register(UserModel user);

  Future<UserModel?> login({
    required String usernameOrEmail,
    required String password,
  });

  Future<void> logout();

  Future<bool> usernameExists(String username);

  Future<bool> emailExists(String email);

  Future<void> requestPasswordReset(String email);

  Future<void> updatePassword({
    required String email,
    required String newPassword,
  });

  Future<UserModel?> getUserById(String id);

  Future<void> sendEmailVerification();

  Future<bool> isEmailVerified();
}
