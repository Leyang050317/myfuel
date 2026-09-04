import 'package:flutter/material.dart';
import '../features/auth/screens/splash_page.dart';
import '../features/auth/screens/login_page.dart';
import '../features/auth/screens/register_page.dart';
import '../features/auth/screens/forgot_password_page.dart';
import '../features/admin/screens/admin_page.dart';
import '../features/admin/screens/add_vehicle_page.dart';
import '../features/admin/screens/manage_vehicles_page.dart';
import '../features/home/screens/home_page.dart';
import '../features/fuel_price/screens/fuel_trend_page.dart';
import '../features/user/screens/fuel_calculator_page.dart';
import '../features/fuel_tracking/screens/fuel_history_page.dart';
import '../features/fuel_tracking/screens/refuel_record_page.dart';
import '../features/fuel_tracking/screens/fuel_dashboard_page.dart';
import '../features/admin/screens/fuel_claims_page.dart';
import '../features/admin/screens/fuel_monitoring_page.dart';
import '../features/admin/screens/live_tracking_page.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String admin = '/admin';
  static const String addVehicle = '/admin/add-vehicle';
  static const String manageVehicles = '/admin/manage-vehicles';
  static const String home = '/home';
  static const String driverPetrolMap = '/home/petrol-map';
  static const String driverTripLog = '/home/trip-log';
  static const String fuelTrend = '/fuel-trend';
  static const String fuelCalculator = '/fuel-calculator';
  static const String fuelClaim = '/fuel-claim';
  static const String fuelHistory = '/fuel-history';
  static const String refuelRecord = '/refuel-record';
  static const String fuelDashboard = '/fuel-dashboard';
  static const String fuelClaims = '/admin/fuel-claims';
  static const String fuelMonitoring = '/admin/fuel-monitoring';
  static const String liveTracking = '/admin/live-tracking';

  static Map<String, WidgetBuilder> get routes => {
    splash: (context) => const SplashPage(),
    login: (context) => const LoginPage(),
    register: (context) => const RegisterPage(),
    forgotPassword: (context) => const ForgotPasswordPage(),
    admin: (context) => const AdminPage(),
    addVehicle: (context) => const AddVehiclePage(),
    manageVehicles: (context) => const ManageVehiclesPage(),
    home: (context) => const HomePage(),
    driverPetrolMap: (context) => const HomePage(initialIndex: 1),
    driverTripLog: (context) => const HomePage(initialIndex: 2),
    fuelTrend: (context) => const FuelTrendPage(),

    fuelCalculator: (context) => const FuelCalculatorPage(),
    fuelClaim: (context) => const FuelCalculatorPage(),
    fuelHistory: (context) => const FuelHistoryPage(),
    refuelRecord: (context) => const RefuelRecordPage(),
    fuelDashboard: (context) => const FuelDashboardPage(),
    fuelClaims: (context) => const FuelClaimsPage(),
    fuelMonitoring: (context) => const FuelMonitoringPage(),
    liveTracking: (context) => const LiveTrackingPage(),
  };
}
