import 'dart:async';

import 'package:flutter/material.dart';
import '../../../routes/app_routes.dart';
import '../../home/widgets/driver_shell.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../fuel_tracking/models/fuel_calculation_result.dart';
import '../../fuel_tracking/models/fuel_claim_model.dart';
import '../../fuel_tracking/services/fuel_claim_service.dart';
import '../database/local_database.dart';

class FuelCalculatorPage extends StatefulWidget {
  const FuelCalculatorPage({super.key});

  @override
  State<FuelCalculatorPage> createState() => _FuelCalculatorPageState();
}

class _FuelCalculatorPageState extends State<FuelCalculatorPage> {
  List<FuelCalculationResult> _trips = [];
  FuelCalculationResult? _selectedTrip;
  final FuelClaimService _claimService = FuelClaimService();
  final Map<String, FuelClaimModel> _claimsByTripId = {};
  StreamSubscription<List<FuelClaimModel>>? _claimSubscription;
  Timer? _claimRefreshTimer;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  String get _userId => Supabase.instance.client.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    unawaited(_loadClaimsFromServer());
    _watchClaims();
    _claimRefreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _loadClaimsFromServer(),
    );
    _loadCompletedTrips();
  }

  @override
  void dispose() {
    _claimSubscription?.cancel();
    _claimRefreshTimer?.cancel();
    super.dispose();
  }

  void _watchClaims() {
    if (_userId.isEmpty) return;
    _claimSubscription = _claimService
        .watchClaimsForUser(_userId)
        .listen(
          (claims) {
            _applyClaims(claims);
          },
          onError: (Object _) {
            // Realtime may not be enabled for fuel_claims. REST polling keeps
            // claim statuses synchronized without showing a fatal UI error.
            unawaited(_loadClaimsFromServer());
          },
        );
  }

  Future<void> _loadClaimsFromServer() async {
    if (_userId.isEmpty) return;
    try {
      _applyClaims(await _claimService.loadClaims(userId: _userId));
    } catch (_) {
      // A temporary network failure must not hide locally completed trips.
    }
  }

  void _applyClaims(List<FuelClaimModel> claims) {
    if (!mounted) return;
    setState(() {
      _claimsByTripId
        ..clear()
        ..addEntries(
          claims
              .where((claim) => claim.tripId != null)
              .map((claim) => MapEntry(claim.tripId!, claim)),
        );
      final selectedTripId = _selectedTrip?.tripId;
      if (selectedTripId != null &&
          _claimsByTripId.containsKey(selectedTripId)) {
        _selectedTrip = null;
      }
    });
  }

  Future<void> _refreshAll() async {
    await Future.wait([_loadCompletedTrips(), _loadClaimsFromServer()]);
  }

  Future<void> _loadCompletedTrips() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final records = await LocalDatabase.instance.loadCompletedTrips(
        userId: _userId,
      );
      if (mounted) {
        setState(() {
          _trips = records.map(FuelCalculationResult.fromHistoryMap).toList();
          if (_selectedTrip != null && !_trips.contains(_selectedTrip)) {
            _selectedTrip = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Unable to load completed trips: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _submitClaim() async {
    if (_selectedTrip == null) return;
    final selectedTrip = _selectedTrip!;
    setState(() => _submitting = true);
    try {
      final tripId = selectedTrip.tripId;
      if (tripId == null || _claimsByTripId.containsKey(tripId)) return;
      await _claimService.submit(selectedTrip);
      await _loadClaimsFromServer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Fuel claim of RM ${selectedTrip.fuelCost.toStringAsFixed(2)} submitted as Pending.',
            ),
          ),
        );
        setState(() => _selectedTrip = null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to submit claim: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DriverShell(
      title: 'Fuel Claim',
      selectedRoute: AppRoutes.fuelCalculator,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh Trips',
          onPressed: _loading ? null : _refreshAll,
        ),
      ],
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Select Completed Trip',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose a completed trip from your device to review calculation and submit a fuel claim.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700,
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
                const SizedBox(height: 16),
                if (_trips.isEmpty)
                  Card(
                    elevation: 0,
                    color: Colors.grey.shade100,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.route_outlined,
                            size: 48,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No Completed Trips Found',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Start and complete a trip in Trip Log to generate a trip calculation snapshot for claims.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ..._trips.map((trip) {
                    final isSelected = _selectedTrip == trip;
                    final claim = trip.tripId == null
                        ? null
                        : _claimsByTripId[trip.tripId!];
                    final hasClaim = claim != null;
                    final dateStr =
                        '${trip.createdAt.day.toString().padLeft(2, '0')}/${trip.createdAt.month.toString().padLeft(2, '0')}/${trip.createdAt.year} ${trip.createdAt.hour.toString().padLeft(2, '0')}:${trip.createdAt.minute.toString().padLeft(2, '0')}';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: hasClaim
                            ? null
                            : () {
                                setState(() {
                                  _selectedTrip = isSelected ? null : trip;
                                });
                              },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: isSelected
                                ? theme.colorScheme.primary.withValues(
                                    alpha: 0.08,
                                  )
                                : Colors.white,
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.directions_car_outlined,
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : Colors.grey.shade700,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      trip.vehicleDisplayName.isNotEmpty
                                          ? trip.vehicleDisplayName
                                          : 'Trip Vehicle',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                  if (claim != null) ...[
                                    const SizedBox(width: 8),
                                    _claimStatusChip(claim.status),
                                  ],
                                  const SizedBox(width: 8),
                                  Text(
                                    'RM ${trip.fuelCost.toStringAsFixed(2)}',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    size: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    dateStr,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    trip.fuelType,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _infoItem(
                                    'Distance',
                                    '${trip.distanceKm.toStringAsFixed(2)} km',
                                  ),
                                  _infoItem(
                                    'Fuel Used',
                                    '${trip.fuelUsedLiters.toStringAsFixed(2)} L',
                                  ),
                                  _infoItem(
                                    'Price/L',
                                    'RM ${trip.fuelPricePerLiter.toStringAsFixed(2)}',
                                  ),
                                  _infoItem(
                                    'CO₂',
                                    '${trip.co2Kg.toStringAsFixed(2)} kg',
                                  ),
                                ],
                              ),
                              if (claim != null) ...[
                                const SizedBox(height: 10),
                                Text(
                                  claim.status == 'Pending'
                                      ? 'This claim is waiting for admin review.'
                                      : claim.status == 'Approved'
                                      ? 'This fuel claim has been approved.'
                                      : 'This fuel claim was rejected${claim.rejectionReason?.isNotEmpty == true ? ': ${claim.rejectionReason}' : '.'}',
                                  style: TextStyle(
                                    color: _claimStatusColor(claim.status),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                if (_selectedTrip != null) ...[
                  const SizedBox(height: 12),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.rate_review_outlined,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Claim Review Snapshot',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _reviewRow(
                            'Vehicle',
                            _selectedTrip!.vehicleDisplayName,
                          ),
                          _reviewRow('Fuel Type', _selectedTrip!.fuelType),
                          _reviewRow(
                            'Efficiency',
                            '${_selectedTrip!.fuelEfficiencyKmPerLiter.toStringAsFixed(2)} km/L',
                          ),
                          _reviewRow(
                            'Distance Travelled',
                            '${_selectedTrip!.distanceKm.toStringAsFixed(2)} km',
                          ),
                          _reviewRow(
                            'Fuel Price at Trip',
                            'RM ${_selectedTrip!.fuelPricePerLiter.toStringAsFixed(2)}/L',
                          ),
                          _reviewRow(
                            'Estimated Fuel Used',
                            '${_selectedTrip!.fuelUsedLiters.toStringAsFixed(2)} L',
                          ),
                          _reviewRow(
                            'Estimated CO₂',
                            '${_selectedTrip!.co2Kg.toStringAsFixed(2)} kg',
                          ),
                          const Divider(height: 20),
                          _reviewRow(
                            'Total Claim Amount',
                            'RM ${_selectedTrip!.fuelCost.toStringAsFixed(2)}',
                            isHighlight: true,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _submitting ? null : _submitClaim,
                              icon: const Icon(Icons.send_rounded),
                              label: Text(
                                _submitting
                                    ? 'SUBMITTING...'
                                    : 'SUBMIT FUEL CLAIM',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _infoItem(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      const SizedBox(height: 2),
      Text(
        value,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    ],
  );

  Widget _reviewRow(String label, String value, {bool isHighlight = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
                color: isHighlight ? Colors.black : Colors.grey.shade700,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isHighlight ? 16 : 14,
                color: isHighlight
                    ? Theme.of(context).colorScheme.primary
                    : Colors.black87,
              ),
            ),
          ],
        ),
      );

  Widget _claimStatusChip(String status) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: _claimStatusColor(status).withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      status,
      style: TextStyle(
        color: _claimStatusColor(status),
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  Color _claimStatusColor(String status) => switch (status) {
    'Approved' => Colors.green.shade700,
    'Rejected' => Colors.red.shade700,
    _ => Colors.orange.shade800,
  };
}
