class PasswordPolicy {
  static const int minLength = 8;
  static const int maxLength = 64;

  static bool isValid(String password) {
    if (password.length < minLength || password.length > maxLength) {
      return false;
    }

    return !RegExp(r'\s').hasMatch(password) &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'\d').hasMatch(password) &&
        RegExp(r'[^A-Za-z0-9\s]').hasMatch(password);
  }
}
