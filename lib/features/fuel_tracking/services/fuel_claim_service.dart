import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/fuel_calculation_result.dart';
import '../models/fuel_claim_model.dart';

class FuelClaimService {
  SupabaseClient get _supabase => Supabase.instance.client;
  Future<void> submit(FuelCalculationResult result, {String? tripId}) async {
    final effectiveTripId = tripId ?? result.tripId;
    if (effectiveTripId == null || effectiveTripId.isEmpty) {
      throw StateError('A completed trip is required for a fuel claim.');
    }
    await _supabase.from('fuel_claims').insert({
      'user_id': result.userId,
      'vehicle_id': result.vehicleId,
      'trip_id': effectiveTripId,
      'vehicle_display_name': result.vehicleDisplayName,
      'distance_km': result.distanceKm,
      'fuel_type': result.fuelType,
      'fuel_efficiency_km_per_liter': result.fuelEfficiencyKmPerLiter,
      'fuel_price_per_liter': result.fuelPricePerLiter,
      'fuel_used_liters': result.fuelUsedLiters,
      'claim_amount': result.fuelCost,
      'co2_kg': result.co2Kg,
      'emission_factor': result.emissionFactor,
      'status': 'Pending',
    });
  }

  Stream<List<FuelClaimModel>> watchClaimsForUser(String userId) {
    return _supabase
        .from('fuel_claims')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map(
          (rows) => rows
              .map((row) => FuelClaimModel.fromJson(row))
              .toList(growable: false),
        );
  }

  Future<List<FuelClaimModel>> loadClaims({String? userId}) async {
    final data = userId == null
        ? await _supabase
              .from('fuel_claims')
              .select()
              .order('created_at', ascending: false)
        : await _supabase
              .from('fuel_claims')
              .select()
              .eq('user_id', userId)
              .order('created_at', ascending: false);
    return (data as List)
        .map((item) => FuelClaimModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateStatus(
    String id,
    String status, {
    String? rejectionReason,
  }) async {
    if (!const {'Approved', 'Rejected'}.contains(status)) {
      throw ArgumentError('Invalid claim status.');
    }
    final updated = await _supabase
        .from('fuel_claims')
        .update({
          'status': status,
          'rejection_reason': rejectionReason,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id)
        .eq('status', 'Pending')
        .select('id, status')
        .maybeSingle();
    if (updated == null) {
      throw StateError(
        'This claim is no longer pending. Refresh and try again.',
      );
    }
  }
}
