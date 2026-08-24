import 'fuel_calculation_result.dart';

class FuelClaimModel {
  final String id;
  final String userId;
  final String vehicleId;
  final String? tripId;
  final FuelCalculationResult calculation;
  final String status;
  final String? rejectionReason;
  final DateTime createdAt;

  const FuelClaimModel({
    required this.id,
    required this.userId,
    required this.vehicleId,
    this.tripId,
    required this.calculation,
    required this.status,
    this.rejectionReason,
    required this.createdAt,
  });

  factory FuelClaimModel.fromJson(Map<String, dynamic> json) {
    double number(String key) => (json[key] as num?)?.toDouble() ?? 0;
    final createdAt =
        DateTime.tryParse(json['created_at']?.toString() ?? '') ??
        DateTime.now();
    return FuelClaimModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      vehicleId: json['vehicle_id']?.toString() ?? '',
      tripId: json['trip_id']?.toString(),
      status: json['status']?.toString() ?? 'Pending',
      rejectionReason: json['rejection_reason']?.toString(),
      createdAt: createdAt,
      calculation: FuelCalculationResult(
        tripId: json['trip_id']?.toString(),
        createdAt: createdAt,
        userId: json['user_id']?.toString() ?? '',
        vehicleId: json['vehicle_id']?.toString() ?? '',
        vehicleDisplayName: json['vehicle_display_name']?.toString() ?? '',
        source: 'claim',
        distanceKm: number('distance_km'),
        fuelType: json['fuel_type']?.toString() ?? '',
        fuelEfficiencyKmPerLiter: number('fuel_efficiency_km_per_liter'),
        fuelPricePerLiter: number('fuel_price_per_liter'),
        fuelUsedLiters: number('fuel_used_liters'),
        fuelCost: number('claim_amount'),
        co2Kg: number('co2_kg'),
        emissionFactor: number('emission_factor'),
      ),
    );
  }
}
