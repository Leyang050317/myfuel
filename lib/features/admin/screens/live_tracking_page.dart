import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../routes/app_routes.dart';
import '../../fuel_tracking/services/live_tracking_service.dart';
import '../models/live_driver_model.dart';
import '../widgets/admin_shell.dart';

class LiveTrackingPage extends StatefulWidget {
  const LiveTrackingPage({super.key});

  @override
  State<LiveTrackingPage> createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends State<LiveTrackingPage> {
  static const _fallbackCenter = LatLng(4.2105, 101.9758);
  static const _colors = <Color>[
    Color(0xFF1565C0),
    Color(0xFFD32F2F),
    Color(0xFF2E7D32),
    Color(0xFF6A1B9A),
    Color(0xFFEF6C00),
    Color(0xFF00838F),
  ];

  final _mapController = MapController();
  final _service = LiveTrackingService();
  final Map<String, List<LatLng>> _trails = {};
  final Map<String, String> _tripIds = {};
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;
  Timer? _refreshTimer;
  List<LiveDriverModel> _drivers = [];
  String? _error;
  bool _mapReady = false;
  bool _hasFittedDrivers = false;
  bool _refreshInProgress = false;
  String? _followedDriverId;

  @override
  void initState() {
    super.initState();
    _subscription = _service.watchDriverLocations().listen(
      _handleLocations,
      onError: (Object error) {
        if (mounted) setState(() => _error = error.toString());
      },
    );
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _refreshLocations(),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshLocations() async {
    if (_refreshInProgress) return;
    _refreshInProgress = true;
    try {
      _handleLocations(await _service.loadDriverLocations());
    } catch (error) {
      if (mounted && _drivers.isEmpty) {
        setState(() => _error = error.toString());
      }
    } finally {
      _refreshInProgress = false;
    }
  }

  void _handleLocations(List<Map<String, dynamic>> rows) {
    if (!mounted) return;
    final cutoff = DateTime.now().toUtc().subtract(const Duration(minutes: 2));
    final drivers = rows
        .where((row) => row['is_active'] == true)
        .map(LiveDriverModel.fromJson)
        .where((driver) => driver.updatedAt.toUtc().isAfter(cutoff))
        .toList();

    final activeUserIds = drivers.map((driver) => driver.userId).toSet();
    _trails.removeWhere((userId, _) => !activeUserIds.contains(userId));
    _tripIds.removeWhere((userId, _) => !activeUserIds.contains(userId));
    if (_followedDriverId != null &&
        !activeUserIds.contains(_followedDriverId)) {
      _followedDriverId = null;
    }
    if (drivers.length == 1) {
      _followedDriverId = drivers.first.userId;
    }

    for (final driver in drivers) {
      if (_tripIds[driver.userId] != driver.tripId) {
        _trails[driver.userId] = [];
        _tripIds[driver.userId] = driver.tripId;
      }
      final trail = _trails.putIfAbsent(driver.userId, () => []);
      if (trail.isEmpty ||
          const Distance().as(LengthUnit.Meter, trail.last, driver.location) >=
              2) {
        trail.add(driver.location);
        if (trail.length > 300) trail.removeAt(0);
      }
    }

    setState(() {
      _drivers = drivers;
      _error = null;
      if (drivers.isEmpty) _hasFittedDrivers = false;
    });
    if (!_hasFittedDrivers && drivers.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitAllDrivers());
    } else if (_followedDriverId != null && _mapReady) {
      final followed = drivers.where(
        (driver) => driver.userId == _followedDriverId,
      );
      if (followed.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _mapReady) {
            _mapController.move(
              followed.first.location,
              _mapController.camera.zoom,
            );
          }
        });
      }
    }
  }

  void _fitAllDrivers() {
    if (!_mapReady || _drivers.isEmpty) return;
    if (_drivers.length == 1) {
      _mapController.move(_drivers.first.location, 16);
    } else {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(
            _drivers.map((driver) => driver.location).toList(),
          ),
          padding: const EdgeInsets.all(70),
        ),
      );
    }
    _hasFittedDrivers = true;
    if (_drivers.length != 1) _followedDriverId = null;
  }

  void _followDriver(LiveDriverModel driver) {
    setState(() => _followedDriverId = driver.userId);
    _mapController.move(driver.location, 17);
  }

  Color _driverColor(String userId) {
    final index = _drivers.indexWhere((driver) => driver.userId == userId);
    return _colors[(index < 0 ? 0 : index) % _colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Live Tracking',
      selectedRoute: AppRoutes.liveTracking,
      actions: [
        Center(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Chip(
              avatar: const Icon(Icons.circle, color: Colors.green, size: 12),
              label: Text('${_drivers.length} active'),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Show all drivers',
          onPressed: _drivers.isEmpty ? null : _fitAllDrivers,
          icon: const Icon(Icons.center_focus_strong),
        ),
      ],
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _fallbackCenter,
                    initialZoom: 6,
                    onMapReady: () {
                      _mapReady = true;
                      _fitAllDrivers();
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.myfuel',
                    ),
                    PolylineLayer(
                      polylines: _drivers
                          .where(
                            (driver) =>
                                (_trails[driver.userId]?.length ?? 0) > 1,
                          )
                          .map(
                            (driver) => Polyline(
                              points: _trails[driver.userId]!,
                              strokeWidth: 4,
                              color: _driverColor(
                                driver.userId,
                              ).withValues(alpha: 0.75),
                            ),
                          )
                          .toList(),
                    ),
                    MarkerLayer(
                      markers: _drivers.map((driver) {
                        final color = _driverColor(driver.userId);
                        return Marker(
                          point: driver.location,
                          width: 130,
                          height: 72,
                          child: GestureDetector(
                            onTap: () {
                              _followDriver(driver);
                              _showDriver(driver);
                            },
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: const [
                                      BoxShadow(
                                        blurRadius: 4,
                                        color: Colors.black26,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    driver.driverName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Transform.rotate(
                                  angle: driver.heading * math.pi / 180,
                                  child: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          blurRadius: 5,
                                          color: Colors.black38,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.directions_car_filled,
                                      color: Colors.white,
                                      size: 23,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                if (_drivers.isEmpty && _error == null)
                  const _MapMessage(
                    icon: Icons.location_searching,
                    message: 'Waiting for active driver trips…',
                  ),
                if (_error != null)
                  _MapMessage(
                    icon: Icons.error_outline,
                    message:
                        'Unable to load live locations. Run live_tracking_schema.sql in Supabase.\n$_error',
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: _drivers.isEmpty
                ? const SizedBox.shrink()
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _drivers.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final driver = _drivers[index];
                      return Card(
                        margin: EdgeInsets.zero,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _driverColor(driver.userId),
                            foregroundColor: Colors.white,
                            child: const Icon(Icons.directions_car),
                          ),
                          title: Text(driver.driverName),
                          subtitle: Text(
                            [
                              if (driver.vehicleName.isNotEmpty)
                                driver.vehicleName,
                              if (driver.plateNumber.isNotEmpty)
                                driver.plateNumber,
                              if (driver.destinationName?.isNotEmpty == true)
                                'To ${driver.destinationName}',
                            ].join(' • '),
                          ),
                          trailing: Text(
                            '${driver.speedKph.toStringAsFixed(0)} km/h\n'
                            '${driver.distanceKm.toStringAsFixed(2)} km',
                            textAlign: TextAlign.right,
                          ),
                          onTap: () {
                            _followDriver(driver);
                            _showDriver(driver);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showDriver(LiveDriverModel driver) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              driver.driverName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text('Vehicle: ${driver.vehicleName} ${driver.plateNumber}'),
            Text('Speed: ${driver.speedKph.toStringAsFixed(1)} km/h'),
            Text('Trip distance: ${driver.distanceKm.toStringAsFixed(2)} km'),
            Text('Destination: ${driver.destinationName ?? 'Not selected'}'),
            Text('Last update: ${driver.updatedAt.toLocal()}'),
          ],
        ),
      ),
    );
  }
}

class _MapMessage extends StatelessWidget {
  const _MapMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 42),
              const SizedBox(height: 10),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
