import 'package:latlong2/latlong.dart';

class LiveDriverModel {
  const LiveDriverModel({
    required this.userId,
    required this.tripId,
    required this.driverName,
    required this.vehicleName,
    required this.plateNumber,
    required this.location,
    required this.speedMps,
    required this.heading,
    required this.distanceKm,
    required this.destinationName,
    required this.startedAt,
    required this.updatedAt,
  });

  final String userId;
  final String tripId;
  final String driverName;
  final String vehicleName;
  final String plateNumber;
  final LatLng location;
  final double speedMps;
  final double heading;
  final double distanceKm;
  final String? destinationName;
  final DateTime startedAt;
  final DateTime updatedAt;

  double get speedKph => speedMps * 3.6;

  factory LiveDriverModel.fromJson(Map<String, dynamic> json) {
    return LiveDriverModel(
      userId: json['user_id']?.toString() ?? '',
      tripId: json['trip_id']?.toString() ?? '',
      driverName: json['driver_name']?.toString() ?? 'Driver',
      vehicleName: json['vehicle_name']?.toString() ?? '',
      plateNumber: json['plate_number']?.toString() ?? '',
      location: LatLng(_number(json['latitude']), _number(json['longitude'])),
      speedMps: _number(json['speed_mps']),
      heading: _number(json['heading']),
      distanceKm: _number(json['distance_km']),
      destinationName: json['destination_name']?.toString(),
      startedAt: _date(json['started_at']),
      updatedAt: _date(json['updated_at']),
    );
  }

  static double _number(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

  static DateTime _date(dynamic value) =>
      DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
}
