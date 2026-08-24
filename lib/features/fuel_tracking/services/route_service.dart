import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/destination_model.dart';
import 'package:latlong2/latlong.dart';
import '../models/route_model.dart';

class RouteService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org/search';
  static const Duration _requestTimeout = Duration(seconds: 15);

  Future<List<DestinationModel>> searchDestination(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final uri = Uri.parse(
      '$_baseUrl'
      '?q=${Uri.encodeQueryComponent(query)}'
      '&format=jsonv2'
      '&limit=10'
      '&countrycodes=my'
      '&addressdetails=1',
    );
    final response = await http.get(uri, headers: {'User-Agent': 'MyFuel/1.0'});

    if (response.statusCode != 200) {
      throw Exception('Failed to search destination');
    }

    final List data = jsonDecode(response.body);

    return data.map((item) {
      final displayName = item['display_name'] as String;
      final parts = displayName.split(',');
      return DestinationModel(
        name: parts.first.trim(),
        address: parts.skip(1).join(',').trim(),
        location: LatLng(double.parse(item['lat']), double.parse(item['lon'])),
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

    late http.Response response;
    try {
      response = await http.get(uri).timeout(_requestTimeout);
    } on TimeoutException {
      throw RouteServiceException('Route request timed out. Please try again.');
    } on http.ClientException catch (error) {
      throw RouteServiceException('Unable to connect to the routing service: $error');
    } catch (error) {
      throw RouteServiceException('Unable to request a route: $error');
    }

    if (response.statusCode != 200) {
      throw RouteServiceException(
        'Unable to get route (HTTP ${response.statusCode}). Please try again.',
      );
    }

    try {
      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) {
        throw const RouteServiceException('The routing service returned an invalid response.');
      }
      if (data['code'] != 'Ok') {
        throw RouteServiceException(
          'The routing service could not create a route (${data['code'] ?? 'unknown error'}).',
        );
      }

      final routes = data['routes'];
      if (routes is! List || routes.isEmpty || routes.first is! Map) {
        throw const RouteServiceException('The routing service returned no route.');
      }
      final route = routes.first as Map<String, dynamic>;
      final geometry = route['geometry'];
      if (geometry is! Map<String, dynamic> || geometry['coordinates'] is! List) {
        throw const RouteServiceException('The routing service returned an invalid route geometry.');
      }

      return RouteModel(
        start: start,
        destination: destination,

        distanceKm: (route['distance'] as num).toDouble() / 1000,

        duration: Duration(seconds: (route['duration'] as num).round()),

        polyline: (geometry['coordinates'] as List)
            .map((point) => LatLng(point[1].toDouble(), point[0].toDouble()))
            .toList(),
      );
    } on RouteServiceException {
      rethrow;
    } on FormatException {
      throw const RouteServiceException('The routing service returned invalid data.');
    } on TypeError {
      throw const RouteServiceException('The routing service returned an incomplete route.');
    } catch (_) {
      throw const RouteServiceException('The routing service returned an invalid route.');
    }
  }
}

class RouteServiceException implements Exception {
  final String message;

  const RouteServiceException(this.message);

  @override
  String toString() => message;
}
