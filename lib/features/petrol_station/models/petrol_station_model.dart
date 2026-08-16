import 'package:latlong2/latlong.dart';

class PetrolStationModel {
  final String id;
  final String name;
  final String brand;
  final String address;
  final LatLng location;
  final List<String> availableFuelTypes;

  const PetrolStationModel({
    required this.id,
    required this.name,
    required this.brand,
    required this.address,
    required this.location,
    required this.availableFuelTypes,
  });
}
