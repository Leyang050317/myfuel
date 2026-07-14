import 'package:latlong2/latlong.dart';

class RouteModel {
  final LatLng start;

  final LatLng destination;

  final double distanceKm;

  final Duration duration;

  final List<LatLng> polyline;

  RouteModel({
    required this.start,
    required this.destination,
    required this.distanceKm,
    required this.duration,
    required this.polyline,
  });
}