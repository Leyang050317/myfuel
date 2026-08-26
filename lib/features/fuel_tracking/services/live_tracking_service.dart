import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../admin/models/vehicle_model.dart';
import '../models/trip_model.dart';

class LiveTrackingService {
  LiveTrackingService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const _table = 'driver_live_locations';
  String? _cachedDriverName;

  Stream<List<Map<String, dynamic>>> watchActiveDrivers() {
    return _client
        .from(_table)
        .stream(primaryKey: ['user_id'])
        .eq('is_active', true)
        .order('updated_at');
  }

  Future<void> publishPosition({
    required Position position,
    required TripModel trip,
    required VehicleModel? vehicle,
    required String? destinationName,
    required LatLng? destination,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    if (_cachedDriverName == null) {
      final profile = await _client
          .from('users')
          .select('full_name')
          .eq('id', user.id)
          .maybeSingle();
      final name = profile?['full_name']?.toString().trim();
      _cachedDriverName = name?.isNotEmpty == true
          ? name
          : (user.email ?? 'Driver');
    }

    await _client.from(_table).upsert({
      'user_id': user.id,
      'trip_id': trip.id,
      'driver_name': _cachedDriverName,
      'vehicle_id': vehicle?.id.isNotEmpty == true ? vehicle!.id : null,
      'vehicle_name': vehicle == null
          ? ''
          : '${vehicle.brand} ${vehicle.model}',
      'plate_number': vehicle?.plateNumber ?? '',
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracy_m': position.accuracy,
      'speed_mps': position.speed < 0 ? 0 : position.speed,
      'heading': position.heading < 0 ? 0 : position.heading,
      'distance_km': trip.totalDistanceKm,
      'destination_name': destinationName,
      'destination_latitude': destination?.latitude,
      'destination_longitude': destination?.longitude,
      'started_at': trip.startTime.toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'is_active': true,
    }, onConflict: 'user_id');
  }

  Future<void> stopPublishing() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client
        .from(_table)
        .update({
          'is_active': false,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('user_id', userId);
  }
}
