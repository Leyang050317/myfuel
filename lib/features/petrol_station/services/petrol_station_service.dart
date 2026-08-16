import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/petrol_station_model.dart';

class PetrolStationService {
  static const int _radiusMeters = 5000;
  static const int _maxStations = 25;
  static final List<Uri> _overpassUris = [
    Uri.parse('https://overpass-api.de/api/interpreter'),
    Uri.parse('https://lz4.overpass-api.de/api/interpreter'),
    Uri.parse('https://overpass.kumi.systems/api/interpreter'),
  ];

  final Distance _distance = const Distance();

  Future<List<PetrolStationModel>> loadNearbyStations({
    required LatLng currentLocation,
  }) async {
    final query = '''
[out:json][timeout:15];
(
  node["amenity"="fuel"](around:$_radiusMeters,${currentLocation.latitude},${currentLocation.longitude});
  way["amenity"="fuel"](around:$_radiusMeters,${currentLocation.latitude},${currentLocation.longitude});
  relation["amenity"="fuel"](around:$_radiusMeters,${currentLocation.latitude},${currentLocation.longitude});
);
out center $_maxStations;
''';

    final response = await _postWithFallback(query);

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final elements = data['elements'] as List<dynamic>? ?? [];

    final stations = elements
        .map((item) => _stationFromOverpass(item as Map<String, dynamic>))
        .whereType<PetrolStationModel>()
        .toList();

    stations.sort((a, b) {
      final aDistance = _distance(currentLocation, a.location);
      final bDistance = _distance(currentLocation, b.location);
      return aDistance.compareTo(bDistance);
    });

    return stations.take(_maxStations).toList();
  }

  Future<http.Response> _postWithFallback(String query) async {
    Object? lastError;

    for (final uri in _overpassUris) {
      try {
        final response = await http
            .post(
              uri,
              headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
                'User-Agent': 'MyFuel/1.0',
              },
              body: {'data': query},
            )
            .timeout(const Duration(seconds: 18));

        if (response.statusCode == 200) {
          return response;
        }

        lastError = 'Overpass ${uri.host} returned ${response.statusCode}';
      } catch (e) {
        lastError = e;
      }
    }

    throw Exception(
      'All Overpass servers are busy or unreachable. Last error: $lastError',
    );
  }

  PetrolStationModel? _stationFromOverpass(Map<String, dynamic> item) {
    final tags = (item['tags'] as Map?)?.cast<String, dynamic>() ?? {};
    final lat = _toDouble(item['lat'] ?? item['center']?['lat']);
    final lon = _toDouble(item['lon'] ?? item['center']?['lon']);

    if (lat == null || lon == null) {
      return null;
    }

    final brand = _cleanText(
      tags['brand'] ?? tags['operator'] ?? tags['name'] ?? 'Petrol Station',
    );
    final name = _cleanText(tags['name'] ?? '$brand Station');

    return PetrolStationModel(
      id: '${item['type']}-${item['id']}',
      name: name,
      brand: brand,
      address: _addressFromTags(tags),
      location: LatLng(lat, lon),
      availableFuelTypes: _fuelTypesFromTags(tags),
    );
  }

  List<String> _fuelTypesFromTags(Map<String, dynamic> tags) {
    final fuelTypes = <String>[];

    if (_tagIsYes(tags['fuel:ron95']) ||
        _tagIsYes(tags['fuel:octane_95']) ||
        _tagIsYes(tags['fuel:gasoline'])) {
      fuelTypes.add('RON95');
    }
    if (_tagIsYes(tags['fuel:ron97']) || _tagIsYes(tags['fuel:octane_97'])) {
      fuelTypes.add('RON97');
    }
    if (_tagIsYes(tags['fuel:diesel'])) {
      fuelTypes.add('Diesel');
    }
    if (_tagIsYes(tags['fuel:electricity']) ||
        _tagIsYes(tags['amenity:ev_charging'])) {
      fuelTypes.add('EV Charging');
    }

    return fuelTypes.isEmpty ? const ['Fuel info unavailable'] : fuelTypes;
  }

  String _addressFromTags(Map<String, dynamic> tags) {
    final parts = [
      tags['addr:housenumber'],
      tags['addr:street'],
      tags['addr:suburb'],
      tags['addr:city'],
      tags['addr:state'],
    ].where((part) => part != null && part.toString().trim().isNotEmpty);

    final address = parts.map((part) => part.toString().trim()).join(', ');
    if (address.isNotEmpty) {
      return address;
    }

    return _cleanText(
      tags['addr:full'] ?? tags['name'] ?? 'Address unavailable',
    );
  }

  bool _tagIsYes(dynamic value) {
    final text = value?.toString().toLowerCase().trim();
    return text == 'yes' || text == 'true' || text == '1';
  }

  String _cleanText(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? 'Petrol Station' : text;
  }

  double? _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '');
  }
}
