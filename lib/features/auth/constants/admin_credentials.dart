class AdminCredentials {
  static const String email = 'admin@myfuel.com';
  static const String password = 'admin123';

  static bool matches({
    required String usernameOrEmail,
    required String inputPassword,
  }) {
    return usernameOrEmail.trim().toLowerCase() == email &&
        inputPassword == password;
  }
}
