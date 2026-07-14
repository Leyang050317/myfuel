import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/services/location_service.dart';
import '../models/destination_model.dart';
import '../models/route_model.dart';
import '../services/fuel_calculator.dart';
import '../services/route_service.dart';
import '../services/trip_service.dart';
import '../widgets/tracking_map.dart';
import '../widgets/trip_bottom_sheet.dart';
import '../widgets/trip_summary_card.dart';
import '../widgets/trip_information_card.dart';
import '../widgets/tracking_controls.dart';

class FuelTrackingPage extends StatefulWidget {
  const FuelTrackingPage({super.key});

  @override
  State<FuelTrackingPage> createState() =>
      _FuelTrackingPageState();
}

class _FuelTrackingPageState
    extends State<FuelTrackingPage> {

  final MapController _mapController = MapController();

  final LocationService _locationService =
  LocationService();

  final TripService _tripService =
      TripService.instance;

  final RouteService _routeService =
  RouteService();

  final TextEditingController
  _searchController =
  TextEditingController();

  StreamSubscription<Position>?
  _positionStream;
  Position? _currentPosition;
  DestinationModel?
  _selectedDestination;
  RouteModel? _plannedRoute;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      _initializeLocation();
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _searchController.dispose();
    super.dispose();
  }
  Future<void> _initializeLocation() async {
    bool granted =
    await _locationService
        .requestPermission();

    if (!granted) return;

    final current =
    await _locationService
        .getCurrentLocation();

    setState(() {
      _currentPosition = current;
    });

    _positionStream =
        _locationService
            .getPositionStream()
            .listen((position) {

          setState(() {
            _currentPosition = position;
          });

          if (_tripService.isTracking) {
            _mapController.move(
              LatLng(
                position.latitude,
                position.longitude,
              ),
              _mapController.camera.zoom,
            );

            _tripService.updateLocation(
              LatLng(
                position.latitude,
                position.longitude,
              ),
            );

            if (_selectedDestination != null) {

              final distance =
              Geolocator.distanceBetween(

                position.latitude,
                position.longitude,

                _selectedDestination!.location.latitude,
                _selectedDestination!.location.longitude,
              );

              if (distance <= 30) {
                _onArrival();
              }
            }
          }
        });
  }

  @override
  Widget build(BuildContext context) {

    final distance =
        _tripService.currentTrip?.totalDistanceKm ?? 0;

    final fuelUsed = FuelCalculator.calculateFuelUsed(distance);

    const fuelPrice = 3.37;

    final fuelCost = FuelCalculator.calculateFuelCost(
      fuelUsed,
      fuelPrice,
    );

    final co2 = FuelCalculator.calculateCO2(fuelUsed);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Fuel Tracking"),
      ),
      body: Stack(
        children: [

          Positioned.fill(
            child: TrackingMap(
              mapController: _mapController,
              currentLocation: LatLng(
                _currentPosition?.latitude ?? 3.1390,
                _currentPosition?.longitude ?? 101.6869,
              ),
              destination: _selectedDestination?.location,
              route: _plannedRoute,
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: double.infinity,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(14),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Search Destination",
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();

                            setState(() {
                              _selectedDestination = null;
                            });
                          },
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),

                      onSubmitted: (value) async {
                        final results =
                        await _routeService.searchDestination(value);
                        if (results.isEmpty) return;
                        final destination = results.first;
                        if (_currentPosition == null) return;
                        final route = await _routeService.getRoute(
                          start: LatLng(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                          ),
                          destination: destination.location,
                        );

                        setState(() {
                          _selectedDestination = destination;
                          _plannedRoute = route;
                          _arrivalHandled = false;
                        });

                        _tripService.setPlannedRoute(
                          distanceKm: route.distanceKm,
                          duration: route.duration,
                        );

                        final bounds = LatLngBounds.fromPoints(route.polyline);
                        _mapController.fitCamera(
                          CameraFit.bounds(
                            bounds: bounds,
                            padding: const EdgeInsets.all(60),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: TripBottomSheet(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    TripSummaryCard(
                      destination: _selectedDestination?.name,
                      remainingDistance: _tripService.remainingDistanceKm,
                      remainingDuration: _tripService.remainingDuration,
                      isTracking: _tripService.isTracking,
                      hasDestination:
                      _selectedDestination != null,

                      onStart: () {
                        _tripService.startTrip();
                        setState(() {});
                      },

                      onStop: () {
                        _tripService.stopTrip();
                        setState(() {});
                      },
                    ),

                    const Divider(height: 28),

                    TripInformationCard(
                      distance: distance,
                      fuelUsed: fuelUsed,
                      fuelCost: fuelCost,
                      co2: co2,

                      status: _tripService.isTracking
                          ? "Tracking"
                          : "Not Tracking",

                      destination: _selectedDestination?.name,
                      estimatedDistance: _plannedRoute?.distanceKm,
                      etaMinutes: _plannedRoute?.duration.inMinutes,
                      remainingDistance: _tripService.remainingDistanceKm,
                      remainingDuration: _tripService.remainingDuration,
                      progress: _tripService.progress,
                      plannedDistance: _tripService.plannedDistanceKm ?? 0,

                      buildInfoRow: _buildInfoRow,
                    ),

                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
  bool _arrivalHandled = false;

  Future<void> _onArrival() async {
    if (_arrivalHandled) return;
    _arrivalHandled = true;
    setState(() {
      _tripService.stopTrip();
    });
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          icon: const Icon(
            Icons.flag_circle,
            color: Colors.green,
            size: 48,
          ),
          title: const Text("You've Arrived!"),
          content: const Text(
            "Trip completed successfully.",
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
    _arrivalHandled = false;
  }
  Widget _buildInfoRow(
      String title,
      String value,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          SizedBox(
            width: 90,
            child: Text(title),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

        ],
      ),
    );
  }

}
