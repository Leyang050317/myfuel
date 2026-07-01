/// Defines the password requirements for the MyFuel application.
///
/// Keeping all password rules in one place makes future maintenance easier.
/// If the password requirements change, only this file needs to be updated.
class PasswordPolicy {
  /// Minimum password length.
  static const int minLength = 8;

  /// Minimum number of alphabetic characters required.
  static const int minLetters = 4;

  /// Minimum number of numeric digits required.
  static const int minDigits = 4;

  /// Returns true if the password satisfies all requirements.
  static bool isValid(String password) {
    if (password.length < minLength) {
      return false;
    }

    final letterCount =
        RegExp(r'[A-Za-z]').allMatches(password).length;

    final digitCount =
        RegExp(r'\d').allMatches(password).length;

    return letterCount >= minLetters &&
        digitCount >= minDigits;
  }
}