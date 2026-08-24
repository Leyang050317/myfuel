import '../../admin/models/vehicle_model.dart';
import '../models/fuel_calculation_result.dart';

class FuelCalculator {
  static const Map<String, double> emissionFactorsKgPerLiter = {
    'RON95': 2.31,
    'RON97': 2.31,
    'Diesel': 2.68,
  };
  static const double abnormalPerformanceThreshold = 0.80;

  static bool supportsFuelType(String fuelType) =>
      emissionFactorsKgPerLiter.containsKey(fuelType);
  static double emissionFactorFor(String fuelType) {
    final factor = emissionFactorsKgPerLiter[fuelType];
    if (factor == null) {
      throw UnsupportedError('$fuelType is not a petroleum fuel type.');
    }
    return factor;
  }

  static FuelCalculationResult calculate({
    String? tripId,
    required VehicleModel vehicle,
    required String userId,
    required double distanceKm,
    required double fuelPricePerLiter,
    required String source,
    DateTime? createdAt,
  }) {
    if (distanceKm < 0) {
      throw ArgumentError.value(
        distanceKm,
        'distanceKm',
        'must not be negative',
      );
    }
    if (vehicle.fuelEfficiencyKmPerLiter <= 0) {
      throw ArgumentError('Vehicle fuel efficiency must be greater than zero.');
    }
    if (fuelPricePerLiter < 0) {
      throw ArgumentError('Fuel price must not be negative.');
    }
    final factor = emissionFactorFor(vehicle.fuelType);
    final fuelUsed = distanceKm / vehicle.fuelEfficiencyKmPerLiter;
    return FuelCalculationResult(
      tripId: tripId,
      createdAt: createdAt ?? DateTime.now(),
      userId: userId,
      vehicleId: vehicle.id,
      vehicleDisplayName: '${vehicle.brand} ${vehicle.model}'.trim(),
      source: source,
      distanceKm: distanceKm,
      fuelType: vehicle.fuelType,
      fuelEfficiencyKmPerLiter: vehicle.fuelEfficiencyKmPerLiter,
      fuelPricePerLiter: fuelPricePerLiter,
      fuelUsedLiters: fuelUsed,
      fuelCost: fuelUsed * fuelPricePerLiter,
      co2Kg: fuelUsed * factor,
      emissionFactor: factor,
    );
  }

  static double calculateActualEfficiency({
    required double distanceKm,
    required double fuelLiters,
  }) {
    if (distanceKm < 0 || fuelLiters <= 0) {
      throw ArgumentError(
        'Distance must be non-negative and fuel must be greater than zero.',
      );
    }
    return distanceKm / fuelLiters;
  }

  static double estimatedRangeKm({
    required double remainingFuelLiters,
    required double efficiencyKmPerLiter,
  }) => remainingFuelLiters < 0 || efficiencyKmPerLiter <= 0
      ? 0
      : remainingFuelLiters * efficiencyKmPerLiter;
  static bool isAbnormal({
    required double expectedEfficiency,
    required double actualEfficiency,
  }) =>
      expectedEfficiency > 0 &&
      actualEfficiency < expectedEfficiency * abnormalPerformanceThreshold;
}
