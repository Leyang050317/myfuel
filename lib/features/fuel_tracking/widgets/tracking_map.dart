import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/route_model.dart';

class TrackingMap extends StatelessWidget {
  final MapController mapController;

  final LatLng currentLocation;

  final LatLng? destination;
  final RouteModel? route;

  const TrackingMap({
    super.key,
    required this.mapController,
    required this.currentLocation,
    this.destination,
    this.route,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,

      options: MapOptions(
        initialCenter: currentLocation,
        initialZoom: 15,
      ),

      children: [

        TileLayer(
          urlTemplate:
          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',

          userAgentPackageName: 'com.myfuel.app',
        ),

        if (route != null)
          PolylineLayer(
            polylines: [
              Polyline(
                points: route!.polyline,
                strokeWidth: 5,
                color: Colors.blue,
              ),
            ],
          ),

        MarkerLayer(
          markers: [

            Marker(
              point: currentLocation,
              width: 45,
              height: 45,
              child: const Icon(
                Icons.location_pin,
                color: Colors.blue,
                size: 40,
              ),
            ),

            if (destination != null)

              Marker(
                point: destination!,
                width: 45,
                height: 45,
                child: const Icon(
                  Icons.flag,
                  color: Colors.red,
                  size: 38,
                ),
              ),

          ],
        ),

      ],
    );
  }
}