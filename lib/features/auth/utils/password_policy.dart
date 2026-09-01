class PasswordPolicy {
  static const int minLength = 8;

  static const int minLetters = 4;

  static const int minDigits = 4;

  static bool isValid(String password) {
    if (password.length < minLength) {
      return false;
    }

    final letterCount = RegExp(r'[A-Za-z]').allMatches(password).length;

    final digitCount = RegExp(r'\d').allMatches(password).length;

    return letterCount >= minLetters && digitCount >= minDigits;
  }
}
