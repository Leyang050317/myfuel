import 'package:latlong2/latlong.dart';
import 'route_model.dart';

class TripModel {
  final DateTime startTime;
  DateTime? endTime;

  LatLng? startLocation;
  LatLng? previousLocation;
  LatLng? currentLocation;
  LatLng? destination;
  RouteModel? route;

  double totalDistanceKm;

  bool isTracking;

  TripModel({
    required this.startTime,
    this.endTime,
    this.startLocation,
    this.previousLocation,
    this.currentLocation,
    this.destination,
    this.totalDistanceKm = 0,
    this.isTracking = false,
  });
}