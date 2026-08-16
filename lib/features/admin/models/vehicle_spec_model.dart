class VehicleSpecModel {
  final String brand;
  final String model;
  final String defaultFuelType;
  final double? defaultFuelEfficiencyKmPerLiter;
  final double? defaultTankCapacityLiters;
  final double? defaultBatteryCapacityKwh;

  const VehicleSpecModel({
    required this.brand,
    required this.model,
    required this.defaultFuelType,
    required this.defaultFuelEfficiencyKmPerLiter,
    required this.defaultTankCapacityLiters,
    required this.defaultBatteryCapacityKwh,
  });

  factory VehicleSpecModel.fromJson(Map<String, dynamic> json) {
    return VehicleSpecModel(
      brand: json['brand'] ?? '',
      model: json['model'] ?? '',
      defaultFuelType: json['default_fuel_type'] ?? 'RON95',
      defaultFuelEfficiencyKmPerLiter: _toDouble(
        json['default_fuel_efficiency_km_per_liter'],
      ),
      defaultTankCapacityLiters: _toDouble(
        json['default_tank_capacity_liters'],
      ),
      defaultBatteryCapacityKwh: _toDouble(
        json['default_battery_capacity_kwh'],
      ),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }
}
