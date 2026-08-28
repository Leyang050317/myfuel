import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/models/user_model.dart';
import '../models/vehicle_model.dart';
import '../models/vehicle_spec_model.dart';

class VehicleService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<UserModel>> loadEmployees() async {
    final data = await _supabase
        .from('users')
        .select(
          'id, full_name, username, email, phone_number, ic_number, email_verified, created_at, updated_at',
        )
        .order('full_name', ascending: true);

    return (data as List<dynamic>)
        .map((item) => UserModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> addVehicle(VehicleModel vehicle) async {
    await _supabase.from('vehicles').insert(vehicle.toJson());
  }

  Future<List<VehicleModel>> loadVehicles() async {
    final data = await _supabase
        .from('vehicles')
        .select()
        .order('created_at', ascending: false);

    return (data as List<dynamic>)
        .map((item) => VehicleModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<VehicleModel?> loadAssignedVehicle(String userId) async {
    final data = await _supabase
        .from('vehicles')
        .select()
        .eq('assigned_user_id', userId)
        .eq('status', 'Assigned')
        .maybeSingle();
    return data == null ? null : VehicleModel.fromJson(data);
  }

  Future<void> updateVehicleAssignment({
    required String vehicleId,
    required String? assignedUserId,
    required String status,
  }) async {
    await _supabase
        .from('vehicles')
        .update({
          'assigned_user_id': assignedUserId,
          'status': assignedUserId == null ? status : 'Assigned',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', vehicleId);
  }

  Future<void> deleteVehicles(List<String> vehicleIds) async {
    if (vehicleIds.isEmpty) {
      return;
    }

    for (final vehicleId in vehicleIds) {
      await _supabase.from('vehicles').delete().eq('id', vehicleId);
    }
  }

  Future<VehicleSpecModel?> getVehicleSpec({
    required String brand,
    required String model,
  }) async {
    final data = await _supabase
        .from('vehicle_specs')
        .select(
          'brand, model, default_fuel_type, default_fuel_efficiency_km_per_liter, default_tank_capacity_liters, default_battery_capacity_kwh',
        )
        .eq('brand', brand)
        .eq('model', model)
        .maybeSingle();

    if (data == null) {
      return null;
    }

    return VehicleSpecModel.fromJson(data);
  }
}
