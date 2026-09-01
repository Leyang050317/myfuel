import 'password_policy.dart';

class Validators {
  Validators._();

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your full name.';
    }

    if (value.trim().length < 3) {
      return 'Full name must contain at least 3 characters.';
    }

    return null;
  }

  static String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a username.';
    }

    if (value.trim().length < 4) {
      return 'Username must be at least 4 characters.';
    }

    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email address.';
    }

    final email = value.trim();
    final emailRegex = RegExp(
      r'^[A-Za-z0-9.!#$%&\x27*+/=?^_`{|}~-]+@'
      r'[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?'
      r'(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$',
    );

    if (email.length > 254 || !emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address.';
    }

    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your phone number.';
    }

    final phoneRegex = RegExp(r'^01\d{8,9}$');

    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Please enter a valid Malaysian phone number.';
    }

    return null;
  }

  static String? validateIC(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your IC number.';
    }

    final icRegex = RegExp(r'^\d{6}-?\d{2}-?\d{4}$');

    if (!icRegex.hasMatch(value.trim())) {
      return 'Please enter a valid IC number.';
    }

    return null;
  }

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
