class FuelCalculationResult {
  final String? tripId;
  final DateTime createdAt;
  final String userId;
  final String vehicleId;
  final String vehicleDisplayName;
  final String source;
  final double distanceKm;
  final String fuelType;
  final double fuelEfficiencyKmPerLiter;
  final double fuelPricePerLiter;
  final double fuelUsedLiters;
  final double fuelCost;
  final double co2Kg;
  final double emissionFactor;

  const FuelCalculationResult({
    this.tripId,
    required this.createdAt,
    required this.userId,
    required this.vehicleId,
    required this.vehicleDisplayName,
    required this.source,
    required this.distanceKm,
    required this.fuelType,
    required this.fuelEfficiencyKmPerLiter,
    required this.fuelPricePerLiter,
    required this.fuelUsedLiters,
    required this.fuelCost,
    required this.co2Kg,
    required this.emissionFactor,
  });

  Map<String, dynamic> toHistoryMap() => {
    'trip_id': tripId,
    'created_at': createdAt.toIso8601String(),
    'user_id': userId,
    'vehicle_id': vehicleId,
    'vehicle_display_name': vehicleDisplayName,
    'source': source,
    'distance_km': distanceKm,
    'fuel_type': fuelType,
    'fuel_efficiency_km_per_liter': fuelEfficiencyKmPerLiter,
    'fuel_price_per_liter': fuelPricePerLiter,
    'fuel_used_liters': fuelUsedLiters,
    'fuel_cost': fuelCost,
    'co2_kg': co2Kg,
    'emission_factor': emissionFactor,
  };

  factory FuelCalculationResult.fromHistoryMap(Map<String, dynamic> map) {
    double number(String key) => (map[key] as num?)?.toDouble() ?? 0;
    return FuelCalculationResult(
      tripId: map['trip_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      userId: map['user_id'] as String? ?? '',
      vehicleId: map['vehicle_id'] as String? ?? '',
      vehicleDisplayName: map['vehicle_display_name'] as String? ?? '',
      source: map['source'] as String? ?? 'manual',
      distanceKm: number('distance_km'),
      fuelType: map['fuel_type'] as String? ?? '',
      fuelEfficiencyKmPerLiter: number('fuel_efficiency_km_per_liter'),
      fuelPricePerLiter: number('fuel_price_per_liter'),
      fuelUsedLiters: number('fuel_used_liters'),
      fuelCost: number('fuel_cost'),
      co2Kg: number('co2_kg'),
      emissionFactor: number('emission_factor'),
    );
  }
}
