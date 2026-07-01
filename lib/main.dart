import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; //testing firebase initializations
import 'package:flutter/material.dart';
import 'app.dart';

/// Entry point of the MyFuel application.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  print("Firebase initialized successfully!");
  print(FirebaseAuth.instance);

  runApp(const App());
}