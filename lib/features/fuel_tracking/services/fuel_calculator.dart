import '../services/fuel_calculator.dart';

class FuelCalculator {
  /// Default vehicle fuel efficiency (km/L)
  static const double defaultFuelEfficiency = 15.0;

  /// Petrol CO₂ emission (kg/L)
  static const double co2PerLitre = 2.31;

  /// Fuel used (L)
  static double calculateFuelUsed(
      double distanceKm, {
        double efficiency = defaultFuelEfficiency,
      }) {
    if (efficiency <= 0) return 0;
    return distanceKm / efficiency;
  }

  /// Fuel cost (RM)
  static double calculateFuelCost(
      double fuelUsed,
      double fuelPricePerLitre,
      ) {
    return fuelUsed * fuelPricePerLitre;
  }

  /// CO₂ emitted (kg)
  static double calculateCO2(double fuelUsed) {
    return fuelUsed * co2PerLitre;
  }
}