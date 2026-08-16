import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/services/location_service.dart';
import '../../fuel_tracking/models/route_model.dart';
import '../../fuel_tracking/services/route_service.dart';
import '../models/petrol_station_model.dart';
import '../services/petrol_station_service.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final _mapController = MapController();
  final _locationService = LocationService();
  final _stationService = PetrolStationService();
  final _routeService = RouteService();
  final _distance = const Distance();

  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  List<PetrolStationModel> _stations = [];
  PetrolStationModel? _selectedStation;
  RouteModel? _route;
  String? _routeStationId;
  bool _isLoading = true;
  bool _permissionDenied = false;
  bool _isLoadingRoute = false;
  String? _stationLoadError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMap();
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    final granted = await _locationService.requestPermission();
    if (!granted) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _permissionDenied = true;
      });
      return;
    }

    try {
      final position = await _locationService.getCurrentLocation();
      await _updateCurrentLocation(position, moveMap: true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _stationLoadError = e.toString();
      });
      return;
    }

    _positionStream = _locationService.getPositionStream().listen((position) {
      _updateCurrentLocation(position);
    });
  }

  Future<void> _updateCurrentLocation(
    Position position, {
    bool moveMap = false,
  }) async {
    final currentLocation = LatLng(position.latitude, position.longitude);
    List<PetrolStationModel> stations = _stations;

    if (_stations.isEmpty) {
      try {
        stations = await _stationService.loadNearbyStations(
          currentLocation: currentLocation,
        );
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _currentPosition = position;
          _stationLoadError = e.toString();
          _isLoading = false;
        });
        return;
      }
    }

    if (!mounted) return;

    setState(() {
      _currentPosition = position;
      _stations = stations;
      _selectedStation ??= stations.isNotEmpty ? stations.first : null;
      _stationLoadError = null;
      _isLoading = false;
    });

    if (moveMap) {
      _moveMapAfterRender(currentLocation, 15);
    }
  }

  void _moveMapAfterRender(LatLng location, double zoom) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mapController.move(location, zoom);
    });
  }

  void _fitRouteAfterRender(RouteModel route) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(route.polyline),
          padding: const EdgeInsets.fromLTRB(60, 80, 60, 260),
        ),
      );
    });
  }

  LatLng? get _currentLatLng {
    final position = _currentPosition;
    if (position == null) {
      return null;
    }
    return LatLng(position.latitude, position.longitude);
  }

  double _distanceToStation(PetrolStationModel station) {
    final current = _currentLatLng;
    if (current == null) {
      return 0;
    }
    return _distance(current, station.location) / 1000;
  }

  Color _brandColor(String brand) {
    switch (brand.toLowerCase()) {
      case 'petronas':
        return const Color(0xFF00A19C);
      case 'shell':
        return const Color(0xFFFFB300);
      case 'caltex':
        return const Color(0xFFD32F2F);
      case 'bhpetrol':
        return const Color(0xFFFF6F00);
      case 'petron':
        return const Color(0xFF1E88E5);
      case 'mobil':
        return const Color(0xFF1565C0);
      case 'esso':
        return const Color(0xFFE53935);
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  void _showStation(PetrolStationModel station) {
    setState(() {
      _selectedStation = station;
      if (_routeStationId != station.id) {
        _route = null;
        _routeStationId = null;
      }
    });
  }

  Future<void> _navigateToStation(PetrolStationModel station) async {
    final current = _currentLatLng;
    if (current == null) {
      return;
    }

    setState(() {
      _isLoadingRoute = true;
    });

    try {
      final route = await _routeService.getRoute(
        start: current,
        destination: station.location,
      );
      if (!mounted) return;

      setState(() {
        _route = route;
        _routeStationId = station.id;
        _selectedStation = station;
        _isLoadingRoute = false;
      });

      _fitRouteAfterRender(route);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingRoute = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to load route: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLocation = _currentLatLng;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_permissionDenied || currentLocation == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Location permission is required to show nearby petrol stations.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: currentLocation,
            initialZoom: 15,
            onTap: (_, __) {
              setState(() {
                _selectedStation = null;
                _route = null;
                _routeStationId = null;
              });
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.myfuel',
            ),
            if (_route != null)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _route!.polyline,
                    color: Colors.blue,
                    strokeWidth: 5,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                Marker(
                  point: currentLocation,
                  width: 52,
                  height: 52,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.14),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.my_location_rounded,
                      color: Colors.blue,
                      size: 34,
                    ),
                  ),
                ),
                ..._stations.map(
                  (station) {
                    final selected = station.id == _selectedStation?.id;
                    final color = _brandColor(station.brand);

                    return Marker(
                      point: station.location,
                      width: selected ? 66 : 56,
                      height: selected ? 66 : 56,
                      child: GestureDetector(
                        onTap: () => _showStation(station),
                        child: Icon(
                          Icons.local_gas_station_rounded,
                          color: color,
                          size: selected ? 46 : 38,
                          shadows: const [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        Positioned(
          right: 16,
          top: 16,
          child: FloatingActionButton.small(
            heroTag: 'centerCurrentLocation',
            backgroundColor: Colors.white,
            foregroundColor: Colors.blue,
            onPressed: () {
              _moveMapAfterRender(currentLocation, 15);
            },
            child: const Icon(Icons.my_location_rounded),
          ),
        ),
        if (_stationLoadError != null)
          Positioned(
            left: 16,
            right: 16,
            top: 76,
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Unable to load petrol stations: $_stationLoadError',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ),
        if (_selectedStation != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: _StationBottomSheet(
              station: _selectedStation!,
              distanceKm: _distanceToStation(_selectedStation!),
              route: _routeStationId == _selectedStation!.id ? _route : null,
              brandColor: _brandColor(_selectedStation!.brand),
              isLoadingRoute: _isLoadingRoute,
              onNavigate: () => _navigateToStation(_selectedStation!),
            ),
          ),
      ],
    );
  }
}

class _StationBottomSheet extends StatelessWidget {
  final PetrolStationModel station;
  final double distanceKm;
  final RouteModel? route;
  final Color brandColor;
  final bool isLoadingRoute;
  final Future<void> Function() onNavigate;

  const _StationBottomSheet({
    required this.station,
    required this.distanceKm,
    required this.route,
    required this.brandColor,
    required this.isLoadingRoute,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: brandColor.withOpacity(0.12),
                  foregroundColor: brandColor,
                  child: const Icon(Icons.local_gas_station_rounded),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        station.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        station.brand,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: brandColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${distanceKm.toStringAsFixed(1)} km',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _InfoLine(
              icon: Icons.place_outlined,
              text: station.address,
            ),
            if (route != null) ...[
              const SizedBox(height: 10),
              _InfoLine(
                icon: Icons.route_outlined,
                text:
                    '${route!.distanceKm.toStringAsFixed(1)} km route - ${route!.duration.inMinutes} min ETA',
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: station.availableFuelTypes
                  .map(
                    (fuelType) => Chip(
                      label: Text(fuelType),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: isLoadingRoute ? null : onNavigate,
              icon: isLoadingRoute
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.directions_rounded),
              label: Text(isLoadingRoute ? 'LOADING ROUTE' : 'NAVIGATE'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoLine({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.onBackground.withOpacity(0.56),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
