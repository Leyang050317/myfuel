import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_model.dart';
import 'auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  static const emailConfirmationRedirect =
      'com.example.myfuel://login-callback/';

  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<void> register(UserModel user) async {
    final response = await _supabase.auth.signUp(
      email: user.email,
      password: user.password,
      emailRedirectTo: emailConfirmationRedirect,
      data: {
        'full_name': user.fullName,
        'username': user.username,
        'phone_number': user.phoneNumber,
        'ic_number': user.icNumber,
      },
    );

    final authUser = response.user;

    if (authUser == null) {
      throw Exception("Supabase returned null user.");
    }

    if (response.session != null) {
      await _ensureUserProfile(authUser);
    }
  }

  @override
  Future<UserModel?> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: usernameOrEmail,
        password: password,
      );

      final authUser = response.user;

      if (authUser == null) {
        return null;
      }

      final data = await _ensureUserProfile(authUser);

      return UserModel.fromJson(data);
    } on AuthException {
      rethrow;
    } on PostgrestException {
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } on AuthException {
      rethrow;
    }
  }

  @override
  Future<bool> isEmailVerified() async {
    final user = _supabase.auth.currentUser;
    return user?.emailConfirmedAt != null;
  }

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<bool> usernameExists(String username) async {
    throw UnimplementedError();
  }

  @override
  Future<bool> emailExists(String email) async {
    throw UnimplementedError();
  }

  @override
  Future<void> updatePassword({
    required String email,
    required String newPassword,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<UserModel?> getUserById(String id) async {
    throw UnimplementedError();
  }

  Future<Map<String, dynamic>> _ensureUserProfile(User authUser) async {
    final existingProfile = await _supabase
        .from('users')
        .select()
        .eq('id', authUser.id)
        .maybeSingle();

    if (existingProfile != null) {
      return existingProfile;
    }

    final metadata = authUser.userMetadata ?? const <String, dynamic>{};

    return await _supabase
        .from('users')
        .insert({
          'id': authUser.id,
          'full_name': metadata['full_name'] ?? '',
          'username': metadata['username'] ?? '',
          'email': authUser.email ?? '',
          'phone_number': metadata['phone_number'] ?? '',
          'ic_number': metadata['ic_number'] ?? '',
        })
        .select()
        .single();
  }
}
