import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../fuel_tracking/models/fuel_calculation_result.dart';

/// Device-only storage for calculation snapshots; shared business records stay in Supabase.
class LocalDatabase {
  LocalDatabase._();
  static final LocalDatabase instance = LocalDatabase._();
  Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    _database = await openDatabase(
      join(await getDatabasesPath(), 'myfuel.db'),
      version: 2,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE fuel_calculation_history ('
          'id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'trip_id TEXT, '
          'created_at TEXT NOT NULL, '
          'user_id TEXT NOT NULL, '
          'vehicle_id TEXT NOT NULL, '
          'vehicle_display_name TEXT NOT NULL, '
          'source TEXT NOT NULL, '
          'distance_km REAL NOT NULL, '
          'fuel_type TEXT NOT NULL, '
          'fuel_efficiency_km_per_liter REAL NOT NULL, '
          'fuel_price_per_liter REAL NOT NULL, '
          'fuel_used_liters REAL NOT NULL, '
          'fuel_cost REAL NOT NULL, '
          'co2_kg REAL NOT NULL, '
          'emission_factor REAL NOT NULL)',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE fuel_calculation_history ADD COLUMN trip_id TEXT;',
          );
        }
      },
    );
    return _database!;
  }

  Future<void> saveCalculation(FuelCalculationResult result) async =>
      (await database).insert(
        'fuel_calculation_history',
        result.toHistoryMap(),
      );
  Future<List<Map<String, dynamic>>> loadCalculations({
    String? userId,
    DateTime? month,
  }) async {
    final conditions = <String>[];
    final args = <Object?>[];
    if (userId != null && userId.isNotEmpty) {
      conditions.add('user_id = ?');
      args.add(userId);
    }
    if (month != null) {
      conditions.add('created_at >= ? AND created_at < ?');
      args
        ..add(DateTime(month.year, month.month).toIso8601String())
        ..add(DateTime(month.year, month.month + 1).toIso8601String());
    }
    return (await database).query(
      'fuel_calculation_history',
      where: conditions.isEmpty ? null : conditions.join(' AND '),
      whereArgs: args,
      orderBy: 'created_at DESC',
    );
  }

  Future<List<Map<String, dynamic>>> loadCompletedTrips({
    required String userId,
  }) async {
    return (await database).query(
      'fuel_calculation_history',
      where: 'user_id = ? AND source = ?',
      whereArgs: [userId, 'trip'],
      orderBy: 'created_at DESC',
    );
  }

  Future<void> deleteCalculation(int id) async => (await database).delete(
    'fuel_calculation_history',
    where: 'id = ?',
    whereArgs: [id],
  );
}
