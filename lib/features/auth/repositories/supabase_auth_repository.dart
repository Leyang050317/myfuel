import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_model.dart';
import 'auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<void> register(UserModel user) async {
    print("===== STEP 1: Signing up =====");

    AuthResponse response;

    try {
      response = await _supabase.auth.signUp(
        email: user.email,
        password: user.password,
      );
    } on AuthException catch (e) {
      print("================================");
      print("AUTH EXCEPTION");
      print("Message: ${e.message}");
      print("Status: ${e.statusCode}");
      print("================================");
      rethrow;
    } catch (e) {
      print("================================");
      print("UNKNOWN ERROR");
      print(e);
      print("================================");
      rethrow;
    }

    print("===== STEP 2 =====");
    print(response.user);

    final authUser = response.user;

    if (authUser == null) {
      throw Exception("Supabase returned null user.");
    }

    print("===== STEP 3: Inserting profile =====");

    try {
      await _supabase.from('users').insert({
        'id': authUser.id,
        'full_name': user.fullName,
        'username': user.username,
        'email': user.email,
        'phone_number': user.phoneNumber,
        'ic_number': user.icNumber,
      });

      print("===== STEP 4: SUCCESS =====");
    } on PostgrestException catch (e) {
      print("==============================");
      print("DATABASE ERROR");
      print("Message: ${e.message}");
      print("Code: ${e.code}");
      print("Details: ${e.details}");
      print("==============================");
      rethrow;
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

      final data = await _supabase
          .from('users')
          .select()
          .eq('id', authUser.id)
          .single();

      return UserModel.fromJson(data);
    } on AuthException {
      rethrow;
    } on PostgrestException{
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
  Future<void> sendEmailVerification() async {
    // Supabase automatically sends the confirmation email during sign-up.
  }

  // ---------- Temporary placeholders ----------

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
}