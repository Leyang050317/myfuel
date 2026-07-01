import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import 'auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FirebaseAuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override//ask are this email and password correct?
  Future<void> register(UserModel user) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: user.email,
      password: user.password,
    );

    final uid = credential.user!.uid;
    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'fullName': user.fullName,
      'username': user.username,
      'email': user.email,
      'phoneNumber': user.phoneNumber,
      'icNumber': user.icNumber,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await credential.user?.sendEmailVerification();
  }

  @override
  Future<UserModel?> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: usernameOrEmail,
      password: password,
    );
    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      return null;
    }
    await firebaseUser.reload();
    final refreshedUser = _auth.currentUser;
    if (refreshedUser == null) {
      return null;
    }
    if (!refreshedUser.emailVerified) {
      throw FirebaseAuthException(
        code: 'email-not-verified',
        message: 'Please verify your email before logging in.',
      );
    }
    final doc = await _firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .get();
    if (!doc.exists) {
      return null;
    }
    return UserModel.fromFirestore(doc);
  }

  @override
  Future<void> logout() {
    throw UnimplementedError();
  }

  @override
  Future<bool> usernameExists(String username) {
    throw UnimplementedError();
  }

  @override
  Future<bool> emailExists(String email) {
    throw UnimplementedError();
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(
      email: email.trim(),
    );
    print('Firebase accepted reset request.');
  }

  @override
  Future<void> updatePassword({
    required String email,
    required String newPassword,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<UserModel?> getUserById(String id) {
    throw UnimplementedError();
  }

  @override
  Future<void> sendEmailVerification() {
    throw UnimplementedError();
  }

  @override
  Future<bool> isEmailVerified() {
    throw UnimplementedError();
  }
}