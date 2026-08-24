import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/refuel_record_model.dart';

class RefuelRecordService {
  final SupabaseClient _supabase = Supabase.instance.client;
  Future<void> save(RefuelRecordModel record) async {
    final previous = await _supabase
        .from('refuel_records')
        .select('odometer_km')
        .eq('vehicle_id', record.vehicleId)
        .lt('refuelled_at', record.date.toIso8601String())
        .order('refuelled_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (previous != null &&
        record.odometerKm < (previous['odometer_km'] as num).toDouble()) {
      throw ArgumentError('Odometer cannot be below the previous record.');
    }
    await _supabase.from('refuel_records').insert(record.toJson());
  }

  Future<List<RefuelRecordModel>> loadForVehicle(String vehicleId) async {
    final data = await _supabase
        .from('refuel_records')
        .select()
        .eq('vehicle_id', vehicleId)
        .order('refuelled_at', ascending: false);
    return (data as List)
        .map((item) => RefuelRecordModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
