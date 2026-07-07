import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'app.dart';

/// Entry point of the MyFuel application.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://rbctfvooqrzdoyzdllua.supabase.co',
    publishableKey: 'sb_publishable_wjZMNBzzC3JU7_ifnyjNFQ_nprN6Gqn',
  );

  runApp(const App());
}