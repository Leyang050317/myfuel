import 'package:latlong2/latlong.dart';

class DestinationModel {
  final String name;
  final String address;
  final LatLng location;

  DestinationModel({
    required this.name,
    required this.address,
    required this.location,
  });
}