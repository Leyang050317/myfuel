class RefuelRecordModel {
  final String id, userId, vehicleId, fuelType, station, notes;
  final DateTime date;
  final double odometerKm, fuelLiters, pricePerLiter, totalCost;
  final bool isFullTank;
  const RefuelRecordModel({
    this.id = '',
    required this.userId,
    required this.vehicleId,
    required this.fuelType,
    required this.date,
    required this.odometerKm,
    required this.fuelLiters,
    required this.pricePerLiter,
    required this.totalCost,
    required this.station,
    required this.isFullTank,
    required this.notes,
  });
  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'vehicle_id': vehicleId,
    'fuel_type': fuelType,
    'refuelled_at': date.toIso8601String(),
    'odometer_km': odometerKm,
    'fuel_liters': fuelLiters,
    'price_per_liter': pricePerLiter,
    'total_cost': totalCost,
    'station_name': station,
    'is_full_tank': isFullTank,
    'notes': notes,
  };
  factory RefuelRecordModel.fromJson(Map<String, dynamic> json) =>
      RefuelRecordModel(
        id: json['id']?.toString() ?? '',
        userId: json['user_id']?.toString() ?? '',
        vehicleId: json['vehicle_id']?.toString() ?? '',
        fuelType: json['fuel_type']?.toString() ?? '',
        date: DateTime.parse(json['refuelled_at'].toString()),
        odometerKm: (json['odometer_km'] as num).toDouble(),
        fuelLiters: (json['fuel_liters'] as num).toDouble(),
        pricePerLiter: (json['price_per_liter'] as num).toDouble(),
        totalCost: (json['total_cost'] as num).toDouble(),
        station: json['station_name']?.toString() ?? '',
        isFullTank: json['is_full_tank'] as bool? ?? false,
        notes: json['notes']?.toString() ?? '',
      );
}
