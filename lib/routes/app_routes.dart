import 'package:flutter/material.dart';
import '../features/auth/screens/splash_page.dart';
import '../features/auth/screens/login_page.dart';
import '../features/auth/screens/register_page.dart';
import '../features/auth/screens/forgot_password_page.dart';
import '../features/home/screens/home_page.dart';

/// Application route name constants and route map definitions.
class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';

  static Map<String, WidgetBuilder> get routes => {
        splash: (context) => const SplashPage(),
        login: (context) => const LoginPage(),
        register: (context) => const RegisterPage(),
        forgotPassword: (context) => const ForgotPasswordPage(),
        home: (context) => const HomePage(),
      };
}
