import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../routes/app_routes.dart';
import '../../admin/models/vehicle_model.dart';
import '../../admin/services/vehicle_service.dart';
import '../../home/widgets/driver_shell.dart';
import '../../user/database/local_database.dart';
import '../models/fuel_calculation_result.dart';
import '../services/fuel_calculator.dart';
import '../services/refuel_record_service.dart';

class FuelDashboardPage extends StatefulWidget {
  const FuelDashboardPage({super.key});
  @override
  State<FuelDashboardPage> createState() => _FuelDashboardPageState();
}

class _FuelDashboardPageState extends State<FuelDashboardPage> {
  DateTime _month = DateTime.now();
  bool _loading = true;
  List<FuelCalculationResult> _results = [];
  VehicleModel? _vehicle;
  double? _actual, _remaining;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    try {
      _vehicle = await VehicleService().loadAssignedVehicle(userId);
      _results = (await LocalDatabase.instance.loadCalculations(
        userId: userId,
        month: _month,
      )).map(FuelCalculationResult.fromHistoryMap).toList();
      if (_vehicle != null) {
        final records = await RefuelRecordService().loadForVehicle(
          _vehicle!.id,
        );
        final full = records.where((item) => item.isFullTank).toList();
        if (full.length >= 2) {
          _actual = FuelCalculator.calculateActualEfficiency(
            distanceKm: full[0].odometerKm - full[1].odometerKm,
            fuelLiters: full[0].fuelLiters,
          );
        }
        if (full.isNotEmpty) {
          final all = (await LocalDatabase.instance.loadCalculations(
            userId: userId,
          )).map(FuelCalculationResult.fromHistoryMap);
          final used = all
              .where(
                (item) =>
                    item.vehicleId == _vehicle!.id &&
                    item.createdAt.isAfter(full[0].date),
              )
              .fold(0.0, (sum, item) => sum + item.fuelUsedLiters);
          _remaining = (_vehicle!.tankCapacityLiters - used)
              .clamp(0, _vehicle!.tankCapacityLiters)
              .toDouble();
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final distance = _results.fold(0.0, (sum, item) => sum + item.distanceKm);
    final fuel = _results.fold(0.0, (sum, item) => sum + item.fuelUsedLiters);
    final cost = _results.fold(0.0, (sum, item) => sum + item.fuelCost);
    final co2 = _results.fold(0.0, (sum, item) => sum + item.co2Kg);
    final efficiency = fuel == 0 ? 0 : distance / fuel;
    final abnormal =
        _actual != null &&
        _vehicle != null &&
        FuelCalculator.isAbnormal(
          expectedEfficiency: _vehicle!.fuelEfficiencyKmPerLiter,
          actualEfficiency: _actual!,
        );
    return DriverShell(
      title: 'Fuel Dashboard',
      selectedRoute: AppRoutes.fuelDashboard,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '${_month.month}/${_month.year} Summary',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_month_outlined),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _month,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(
                          () => _month = DateTime(date.year, date.month),
                        );
                        _load();
                      }
                    },
                  ),
                ),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _metric(
                      'Total Distance',
                      '${distance.toStringAsFixed(1)} km',
                    ),
                    _metric('Total Fuel', '${fuel.toStringAsFixed(1)} L'),
                    _metric('Total Cost', 'RM ${cost.toStringAsFixed(2)}'),
                    _metric(
                      'Average Efficiency',
                      '${efficiency.toStringAsFixed(2)} km/L',
                    ),
                    _metric('Total CO₂', '${co2.toStringAsFixed(2)} kg'),
                  ],
                ),
                if (_actual != null && _vehicle != null)
                  Card(
                    child: ListTile(
                      title: Text(
                        abnormal
                            ? '⚠ Abnormal fuel consumption'
                            : 'Fuel Performance',
                      ),
                      subtitle: Text(
                        'Expected: ${_vehicle!.fuelEfficiencyKmPerLiter.toStringAsFixed(2)} km/L\nActual: ${_actual!.toStringAsFixed(2)} km/L',
                      ),
                    ),
                  ),
                if (_remaining != null && _vehicle != null)
                  Card(
                    child: ListTile(
                      title: const Text('Estimated Driving Range'),
                      subtitle: Text(
                        '${FuelCalculator.estimatedRangeKm(remainingFuelLiters: _remaining!, efficiencyKmPerLiter: _vehicle!.fuelEfficiencyKmPerLiter).toStringAsFixed(0)} km, based on last full tank and local estimates',
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _metric(String title, String value) => SizedBox(
    width: 170,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    ),
  );
}
