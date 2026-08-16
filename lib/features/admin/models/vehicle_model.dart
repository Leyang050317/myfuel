class VehicleModel {
  final String id;
  final String plateNumber;
  final String brand;
  final String model;
  final String fuelType;
  final double fuelEfficiencyKmPerLiter;
  final double tankCapacityLiters;
  final String? assignedUserId;
  final String status;
  final String notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const VehicleModel({
    this.id = '',
    required this.plateNumber,
    required this.brand,
    required this.model,
    required this.fuelType,
    required this.fuelEfficiencyKmPerLiter,
    required this.tankCapacityLiters,
    required this.assignedUserId,
    required this.status,
    required this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] ?? '',
      plateNumber: json['plate_number'] ?? '',
      brand: json['brand'] ?? '',
      model: json['model'] ?? '',
      fuelType: json['fuel_type'] ?? '',
      fuelEfficiencyKmPerLiter: _toDouble(
        json['fuel_efficiency_km_per_liter'],
      ),
      tankCapacityLiters: _toDouble(json['tank_capacity_liters']),
      assignedUserId: json['assigned_user_id'],
      status: json['status'] ?? 'Available',
      notes: json['notes'] ?? '',
      createdAt: _toDateTime(json['created_at']),
      updatedAt: _toDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    final now = DateTime.now().toIso8601String();

    return {
      'plate_number': plateNumber,
      'brand': brand,
      'model': model,
      'fuel_type': fuelType,
      'fuel_efficiency_km_per_liter': fuelEfficiencyKmPerLiter,
      'tank_capacity_liters': tankCapacityLiters,
      'assigned_user_id': assignedUserId,
      'status': status,
      'notes': notes,
      'created_at': now,
      'updated_at': now,
    };
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value.toString());
  }
}
