import 'password_policy.dart';

class Validators {
  Validators._();

  static String? validateName(String? value) {
    final name = value?.trim() ?? '';

    if (name.isEmpty) {
      return 'Please enter your full name.';
    }

    if (name.length < 2 || name.length > 100) {
      return 'Full name must be between 2 and 100 characters.';
    }

    if (!RegExp(r"^[A-Za-z .'/\-]+$").hasMatch(name)) {
      return 'Full name can only use letters, spaces, . \' - and /.';
    }

    return null;
  }

  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a username.';
    }

    if (RegExp(r'\s').hasMatch(value)) {
      return 'Username must not contain spaces.';
    }

    if (value.length < 3 || value.length > 30) {
      return 'Username must be between 3 and 30 characters.';
    }

    if (!RegExp(r'^[A-Za-z0-9]').hasMatch(value)) {
      return 'Username must start with a letter or number.';
    }

    if (value.endsWith('.')) {
      return 'Username must not end with a period.';
    }

    if (!RegExp(r'^[A-Za-z0-9_.]+$').hasMatch(value)) {
      return 'Username can only use letters, numbers, underscores, and periods.';
    }

    return null;
  }

  static String? validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Please enter your email address.';
    }

    if (email.length > 254) {
      return 'Email address must not exceed 254 characters.';
    }

    if (RegExp(r'\s').hasMatch(email)) {
      return 'Email address must not contain spaces.';
    }

    final parts = email.split('@');
    if (parts.length != 2) {
      return 'Email address must contain exactly one @ symbol.';
    }

    final localPart = parts.first;
    final domain = parts.last;

    if (localPart.isEmpty) {
      return 'Email address must have a username before the @ symbol.';
    }

    if (domain.isEmpty) {
      return 'Email address must have a domain after the @ symbol.';
    }

    if (!RegExp(r'^[A-Za-z0-9.!#$%&\x27*+/=?^_`{|}~-]+$')
        .hasMatch(localPart) ||
        localPart.startsWith('.') ||
        localPart.endsWith('.') ||
        localPart.contains('..')) {
      return 'Email username contains invalid characters or dot placement.';
    }

    final labels = domain.split('.');
    if (labels.length < 2 || labels.any((label) => label.isEmpty)) {
      return 'Email domain must include an extension, such as .com or .my.';
    }

    if (labels.any(
      (label) => !RegExp(r'^[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?$')
          .hasMatch(label),
    )) {
      return 'Email domain contains invalid characters or hyphen placement.';
    }

    if (!RegExp(r'^[A-Za-z]{2,63}$').hasMatch(labels.last)) {
      return 'Email domain must end with a valid extension, such as .com or .my.';
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

    final missingRequirements = <String>[];

    if (value.length < PasswordPolicy.minLength ||
        value.length > PasswordPolicy.maxLength) {
      missingRequirements.add(
        '${PasswordPolicy.minLength}-${PasswordPolicy.maxLength} characters',
      );
    }
    if (RegExp(r'\s').hasMatch(value)) {
      missingRequirements.add('no spaces');
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      missingRequirements.add('an uppercase letter');
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      missingRequirements.add('a lowercase letter');
    }
    if (!RegExp(r'\d').hasMatch(value)) {
      missingRequirements.add('a number');
    }
    if (!RegExp(r'[^A-Za-z0-9\s]').hasMatch(value)) {
      missingRequirements.add('a special character');
    }

    if (missingRequirements.isNotEmpty) {
      return 'Password needs: ${missingRequirements.join(', ')}.';
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
