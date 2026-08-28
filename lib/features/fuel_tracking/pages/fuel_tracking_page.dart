import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/services/location_service.dart';
import '../models/destination_model.dart';
import '../models/route_model.dart';
import '../services/fuel_calculator.dart';
import '../services/live_tracking_service.dart';
import '../services/route_service.dart';
import '../services/trip_service.dart';
import '../widgets/tracking_map.dart';
import '../widgets/trip_bottom_sheet.dart';
import '../widgets/trip_summary_card.dart';
import '../widgets/trip_information_card.dart';
import '../../admin/models/vehicle_model.dart';
import '../../admin/services/vehicle_service.dart';
import '../../fuel_price/services/fuel_price_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../user/database/local_database.dart';

class FuelTrackingPage extends StatefulWidget {
  const FuelTrackingPage({super.key});

  @override
  State<FuelTrackingPage> createState() => _FuelTrackingPageState();
}

class _FuelTrackingPageState extends State<FuelTrackingPage>
    with WidgetsBindingObserver {
  final MapController _mapController = MapController();

  final LocationService _locationService = LocationService();

  final TripService _tripService = TripService.instance;
  final LiveTrackingService _liveTrackingService = LiveTrackingService();

  final RouteService _routeService = RouteService();

  final TextEditingController _searchController = TextEditingController();

  StreamSubscription<Position>? _positionStream;
  Timer? _gpsWatchdog;
  Position? _currentPosition;
  DateTime? _lastPositionReceivedAt;
  bool _positionPollInProgress = false;
  final Distance _distance = const Distance();
  DestinationModel? _selectedDestination;
  RouteModel? _plannedRoute;
  List<DestinationModel> _searchResults = [];
  Timer? _searchDebounce;
  VehicleModel? _calculationVehicle;
  double? _fuelPrice;
  String? _calculationError;
  String? _liveTrackingError;
  DateTime? _lastLivePublishAt;
  bool _livePublishInProgress = false;
  Position? _pendingLivePosition;
  bool _isMapReady = false;
  bool _isCheckingVehicle = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocation();
    });
    _loadCalculationContext();
  }

  Future<bool> _loadCalculationContext() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) {
        setState(() {
          _calculationVehicle = null;
          _fuelPrice = null;
          _calculationError = 'Please sign in before starting a trip.';
          _isCheckingVehicle = false;
        });
      }
      return false;
    }
    if (mounted) setState(() => _isCheckingVehicle = true);
    try {
      final vehicle = await VehicleService().loadAssignedVehicle(userId);
      if (vehicle == null) {
        if (mounted) {
          setState(() {
            _calculationVehicle = null;
            _fuelPrice = null;
            _calculationError = 'No vehicle is assigned to this user.';
          });
        }
        return false;
      }
      if (!FuelCalculator.supportsFuelType(vehicle.fuelType)) {
        throw UnsupportedError(
          '${vehicle.fuelType} is not supported by the petroleum calculator.',
        );
      }
      final price = await FuelPriceService().getCurrentPriceForFuelType(
        vehicle.fuelType,
      );
      if (mounted) {
        setState(() {
          _calculationVehicle = vehicle;
          _fuelPrice = price;
          _calculationError = null;
        });
      }
      return true;
    } catch (e) {
      if (mounted) {
        setState(() {
          _calculationVehicle = null;
          _fuelPrice = null;
          _calculationError = e.toString();
        });
      }
      return false;
    } finally {
      if (mounted) setState(() => _isCheckingVehicle = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _positionStream?.cancel();
    _gpsWatchdog?.cancel();
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    bool granted = await _locationService.requestPermission();

    if (!mounted || !granted) return;

    final current = await _locationService.getCurrentLocation();
    if (!mounted) return;

    _handlePosition(current);
    _startGpsWatchdog();

    await _startPositionStream();
  }

  void _startGpsWatchdog() {
    _gpsWatchdog?.cancel();
    _gpsWatchdog = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _pollPositionIfStreamIsStale(),
    );
  }

  Future<void> _pollPositionIfStreamIsStale() async {
    if (!mounted || _positionPollInProgress) return;
    final lastUpdate = _lastPositionReceivedAt;
    if (lastUpdate != null &&
        DateTime.now().difference(lastUpdate) < const Duration(seconds: 5)) {
      return;
    }

    _positionPollInProgress = true;
    try {
      _handlePosition(await _locationService.getCurrentLocation());
    } catch (_) {
      // The position stream error handler already informs the user. Keep the
      // watchdog alive so it can recover automatically when GPS returns.
    } finally {
      _positionPollInProgress = false;
    }
  }

  Future<void> _startPositionStream({bool? enableBackgroundTracking}) async {
    await _positionStream?.cancel();
    if (!mounted) return;

    _positionStream = _locationService
        .getPositionStream(
          enableBackgroundTracking:
              enableBackgroundTracking ?? _tripService.isTracking,
        )
        .listen(
          _handlePosition,
          onError: (Object error) {
            if (!mounted) return;
            _lastPositionReceivedAt = null;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Live location tracking stopped: $error')),
            );
          },
        );
  }

  void _handlePosition(Position position) {
    if (!mounted) return;
    _lastPositionReceivedAt = DateTime.now();
    setState(() => _currentPosition = position);

    final location = LatLng(position.latitude, position.longitude);
    if (_followUser || !_hasCenteredOnUser || _tripService.isTracking) {
      _moveMapToLocation(location, _hasCenteredOnUser ? null : 16);
    }

    if (!_tripService.isTracking) return;
    _tripService.updateLocation(location);
    unawaited(_publishLivePosition(position));

    final destination = _selectedDestination;
    if (destination == null) return;
    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      destination.location.latitude,
      destination.location.longitude,
    );
    if (distance <= 30) {
      unawaited(_onArrival());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_startPositionStream());
      if (!_tripService.isTracking) {
        unawaited(_loadCalculationContext());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentPosition == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final distance = _tripService.currentTrip?.totalDistanceKm ?? 0;
    final calculation = _calculationVehicle != null && _fuelPrice != null
        ? FuelCalculator.calculate(
            vehicle: _calculationVehicle!,
            userId: Supabase.instance.client.auth.currentUser?.id ?? '',
            distanceKm: distance,
            fuelPricePerLiter: _fuelPrice!,
            source: 'trip',
          )
        : null;
    final fuelUsed = calculation?.fuelUsedLiters ?? 0.0;
    final fuelCost = calculation?.fuelCost ?? 0.0;
    final co2 = calculation?.co2Kg ?? 0.0;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: TrackingMap(
              mapController: _mapController,
              currentLocation: LatLng(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
              ),
              destination: _selectedDestination?.location,
              route: _plannedRoute,
              onMapReady: _onMapReady,
              onMapMoved: () {
                setState(() {
                  _followUser = false;
                });
              },
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
                            FocusScope.of(context).unfocus();
                            setState(() {
                              _selectedDestination = null;
                              _plannedRoute = null;
                              _searchResults.clear();
                            });
                          },
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),

                      onChanged: (value) {
                        _searchDebounce?.cancel();
                        _searchDebounce = Timer(
                          const Duration(milliseconds: 300),
                          () async {
                            if (value.trim().isEmpty) {
                              setState(() {
                                _searchResults.clear();
                              });
                              return;
                            }
                            final results = await _routeService
                                .searchDestination(value);
                            results.sort((a, b) {
                              final distanceA = _distance(
                                LatLng(
                                  _currentPosition!.latitude,
                                  _currentPosition!.longitude,
                                ),
                                a.location,
                              );

                              final distanceB = _distance(
                                LatLng(
                                  _currentPosition!.latitude,
                                  _currentPosition!.longitude,
                                ),
                                b.location,
                              );
                              return distanceA.compareTo(distanceB);
                            });
                            setState(() {
                              _searchResults = results;
                            });
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_searchResults.isNotEmpty)
            Positioned(
              top: 88,
              left: 16,
              right: 16,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(14),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 250),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final destination = _searchResults[index];

                      return ListTile(
                        leading: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                        ),
                        title: Row(
                          children: [
                            Expanded(child: Text(destination.name)),
                            Text(
                              "${(_distance(LatLng(_currentPosition!.latitude, _currentPosition!.longitude), destination.location) / 1000).toStringAsFixed(1)} km",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),

                        subtitle: Text(
                          destination.address,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        onTap: () async {
                          FocusScope.of(context).unfocus();
                          // Fill search bar
                          _searchController.text = destination.name;
                          // Hide suggestion list
                          setState(() {
                            _searchResults.clear();
                            _selectedDestination = destination;
                          });

                          // Calculate route
                          try {
                            final route = await _routeService.getRoute(
                              start: LatLng(
                                _currentPosition!.latitude,
                                _currentPosition!.longitude,
                              ),
                              destination: destination.location,
                            );
                            if (!mounted) return;

                            setState(() {
                              _plannedRoute = route;
                            });
                            _tripService.setPlannedRoute(
                              distanceKm: route.distanceKm,
                              duration: route.duration,
                            );

                            if (_isMapReady) {
                              _mapController.fitCamera(
                                CameraFit.bounds(
                                  bounds: LatLngBounds.fromPoints(
                                    route.polyline,
                                  ),
                                  padding: const EdgeInsets.all(60),
                                ),
                              );
                            }
                          } on RouteServiceException catch (error) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error.message)),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          Positioned(
            left: 16,
            bottom: 230,
            child: FloatingActionButton(
              heroTag: "followButton",
              mini: true,
              backgroundColor: _followUser ? Colors.blue : Colors.grey,
              child: const Icon(Icons.my_location, color: Colors.white),
              onPressed: () {
                if (_currentPosition == null) return;
                setState(() {
                  _followUser = true;
                });
                _moveMapToLocation(
                  LatLng(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
                  ),
                );
              },
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
                      hasDestination: _selectedDestination != null,
                      hasAssignedVehicle: _calculationVehicle != null,
                      isCheckingVehicle: _isCheckingVehicle,

                      onStart: _startTrip,

                      onStop: _stopTrip,
                      onRefreshVehicle: _loadCalculationContext,
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
                    if (_calculationError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Fuel calculation unavailable: $_calculationError',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    if (_liveTrackingError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Admin live tracking unavailable: $_liveTrackingError',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
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

  bool _hasCenteredOnUser = false;
  bool _arrivalHandled = false;
  bool _followUser = true;

  void _onMapReady() {
    if (!mounted) return;
    _isMapReady = true;
    final position = _currentPosition;
    if (position != null) {
      _moveMapToLocation(LatLng(position.latitude, position.longitude), 16);
    }
  }

  void _moveMapToLocation(LatLng location, [double? zoom]) {
    if (!mounted || !_isMapReady) return;
    _mapController.move(location, zoom ?? _mapController.camera.zoom);
    _hasCenteredOnUser = true;
  }

  Future<void> _onArrival() async {
    if (_arrivalHandled) return;
    _arrivalHandled = true;
    setState(() {
      _tripService.stopTrip();
    });
    unawaited(_liveTrackingService.stopPublishing());
    unawaited(_startPositionStream(enableBackgroundTracking: false));
    await _saveTripCalculation();
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          icon: const Icon(Icons.flag_circle, color: Colors.green, size: 48),
          title: const Text("You've Arrived!"),
          content: const Text("Trip completed successfully."),
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

  Future<void> _startTrip() async {
    if (_selectedDestination == null || _currentPosition == null) return;

    final hasVehicle = await _loadCalculationContext();
    if (!mounted || !hasVehicle || _calculationVehicle == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Trip cannot start because no vehicle is assigned to you.',
            ),
          ),
        );
      }
      return;
    }

    _tripService.startTrip();
    setState(() => _followUser = true);
    final position = _currentPosition!;
    _moveMapToLocation(LatLng(position.latitude, position.longitude), 16);
    unawaited(_startPositionStream(enableBackgroundTracking: true));
    unawaited(_publishLivePosition(position, force: true));
  }

  Future<void> _stopTrip() async {
    _tripService.stopTrip();
    _searchController.clear();
    setState(() {
      _plannedRoute = null;
      _selectedDestination = null;
      _searchResults.clear();
    });
    unawaited(_startPositionStream(enableBackgroundTracking: false));
    try {
      await _liveTrackingService.stopPublishing();
      if (mounted && _liveTrackingError != null) {
        setState(() => _liveTrackingError = null);
      }
    } catch (error) {
      if (mounted) setState(() => _liveTrackingError = error.toString());
    }
    await _saveTripCalculation();
  }

  Future<void> _saveTripCalculation() async {
    if (_calculationVehicle == null || _fuelPrice == null) return;
    final distance = _tripService.currentTrip?.totalDistanceKm ?? 0;
    if (distance <= 0) return;
    try {
      await LocalDatabase.instance.saveCalculation(
        FuelCalculator.calculate(
          tripId: _tripService.currentTrip?.id,
          vehicle: _calculationVehicle!,
          userId: Supabase.instance.client.auth.currentUser?.id ?? '',
          distanceKm: distance,
          fuelPricePerLiter: _fuelPrice!,
          source: 'trip',
        ),
      );
    } catch (_) {
      // Local history failure must not interrupt trip completion.
    }
  }

  Future<void> _publishLivePosition(
    Position position, {
    bool force = false,
  }) async {
    final trip = _tripService.currentTrip;
    if (trip == null || !trip.isTracking) return;
    if (_livePublishInProgress) {
      _pendingLivePosition = position;
      return;
    }

    final now = DateTime.now();
    if (!force &&
        _lastLivePublishAt != null &&
        now.difference(_lastLivePublishAt!) < const Duration(seconds: 2)) {
      return;
    }

    _livePublishInProgress = true;
    try {
      await _liveTrackingService.publishPosition(
        position: position,
        trip: trip,
        vehicle: _calculationVehicle,
        destinationName: _selectedDestination?.name,
        destination: _selectedDestination?.location,
      );
      _lastLivePublishAt = now;
      if (mounted && _liveTrackingError != null) {
        setState(() => _liveTrackingError = null);
      }
    } catch (error) {
      if (mounted) setState(() => _liveTrackingError = error.toString());
    } finally {
      _livePublishInProgress = false;
      final pendingPosition = _pendingLivePosition;
      _pendingLivePosition = null;
      if (pendingPosition != null && _tripService.isTracking) {
        unawaited(_publishLivePosition(pendingPosition, force: true));
      }
    }
  }

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(title)),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
