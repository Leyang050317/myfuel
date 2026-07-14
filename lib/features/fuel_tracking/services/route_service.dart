import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/destination_model.dart';
import 'package:latlong2/latlong.dart';
import '../models/route_model.dart';

class RouteService {
  static const String _baseUrl =
      'https://nominatim.openstreetmap.org/search';

  Future<List<DestinationModel>> searchDestination(String query,) async {

    if (query.trim().isEmpty) {
      return [];
    }

    final uri = Uri.parse(
      '$_baseUrl?q=$query&format=jsonv2&limit=5',
    );

    final response = await http.get(
      uri,
      headers: {
        'User-Agent': 'MyFuel/1.0',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to search destination');
    }

    final List data = jsonDecode(response.body);

    return data.map((item) {

      return DestinationModel(

        name: item['display_name'],

        address: item['display_name'],

        location: LatLng(
          double.parse(item['lat']),
          double.parse(item['lon']),
        ),

      );

    }).toList();
  }

  Future<RouteModel> getRoute({
    required LatLng start,
    required LatLng destination,
  }) async {

    final uri = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
          '${start.longitude},${start.latitude};'
          '${destination.longitude},${destination.latitude}'
          '?overview=full&geometries=geojson',
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception("Unable to get route");
    }

    final data = jsonDecode(response.body);

    final route = data["routes"][0];

    return RouteModel(
      start: start,
      destination: destination,

      distanceKm: route["distance"] / 1000,

      duration: Duration(
        seconds: route["duration"].round(),
      ),

      polyline: (route["geometry"]["coordinates"] as List)
          .map(
            (point) => LatLng(
          point[1].toDouble(),
          point[0].toDouble(),
        ),
      )
          .toList(),
    );
  }

}