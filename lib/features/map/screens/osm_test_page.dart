import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../../../core/services/location_service.dart';

class OSMTestPage extends StatefulWidget {
  const OSMTestPage({super.key});

  @override
  State<OSMTestPage> createState() => _OSMTestPageState();
}

class _OSMTestPageState extends State<OSMTestPage> {
  /// Variables
  Position? _currentPosition; ///latest GPS locations
  final MapController _mapController = MapController(); ///Move map automatically
  final LocationService _locationService =
  LocationService();
  StreamSubscription<Position>? _positionStream;
  //get current locations

  Future<void> _initializeLocation() async {

    bool granted =
    await _locationService.requestPermission();

    if (!granted) return;

    Position current =
    await _locationService.getCurrentLocation();

    setState(() {

      _currentPosition = current;

    });

    _mapController.move(

      LatLng(
        current.latitude,
        current.longitude,
      ),

      17,

    );

    _positionStream =
        _locationService
            .getPositionStream()
            .listen((position) {

          setState(() {

            _currentPosition = position;

          });

          _mapController.move(

            LatLng(
              position.latitude,
              position.longitude,
            ),

            _mapController.camera.zoom,

          );

        });

  }


  @override
  void initState() {

    super.initState();

    _initializeLocation();

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentPosition == null
              ? "Getting Location..."
              : "${_currentPosition!.latitude}, ${_currentPosition!.longitude}",
        ),
      ),
      body: FlutterMap(
        mapController: _mapController,

        options: const MapOptions(
          initialCenter: LatLng(3.1390, 101.6869), // Kuala Lumpur
          initialZoom: 15,
        ),
        children: [
          TileLayer(
            urlTemplate:
            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.myfuel',
          ),

          MarkerLayer(
            markers: _currentPosition == null
                ? []
                : [
              Marker(
                point: LatLng(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                ),
                width: 50,
                height: 50,
                child: const Icon(
                  Icons.my_location,
                  color: Colors.blue,
                  size: 40,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }
}