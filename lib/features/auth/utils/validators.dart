import 'password_policy.dart';

/// Provides reusable validation methods for authentication forms.
///
/// Every validation method returns:
/// - `null` if the input is valid.
/// - An error message if the input is invalid.
class Validators {
  Validators._();

  /// Validates full name.
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your full name.';
    }

    if (value.trim().length < 3) {
      return 'Full name must contain at least 3 characters.';
    }

    return null;
  }

  /// Validates username.
  static String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a username.';
    }

    if (value.trim().length < 4) {
      return 'Username must be at least 4 characters.';
    }

    return null;
  }

  /// Validates email address.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email address.';
    }

    final emailRegex =
    RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address.';
    }

    return null;
  }

  /// Validates Malaysian phone number.
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your phone number.';
    }

    final phoneRegex =
    RegExp(r'^01[0-9]-?[0-9]{7,8}$');

    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Please enter a valid Malaysian phone number.';
    }

    return null;
  }

  /// Validates Malaysian IC number.
  static String? validateIC(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your IC number.';
    }

    final icRegex =
    RegExp(r'^\d{6}-?\d{2}-?\d{4}$');

    if (!icRegex.hasMatch(value.trim())) {
      return 'Please enter a valid IC number.';
    }

    return null;
  }

  /// Validates password.
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password.';
    }

    if (!PasswordPolicy.isValid(value)) {
      return 'Password must contain at least '
          '${PasswordPolicy.minLength} characters, '
          '${PasswordPolicy.minLetters} letters and '
          '${PasswordPolicy.minDigits} digits.';
    }

    return null;
  }

  /// Validates confirm password.
  static String? validateConfirmPassword(
      String? value,
      String originalPassword,
      ) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password.';
    }

    if (value != originalPassword) {
      return 'Passwords do not match.';
    }

    return null;
  }
}