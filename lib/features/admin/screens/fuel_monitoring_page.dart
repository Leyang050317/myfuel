import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../routes/app_routes.dart';
import '../widgets/admin_shell.dart';

class FuelMonitoringPage extends StatefulWidget {
  const FuelMonitoringPage({super.key});

  @override
  State<FuelMonitoringPage> createState() => _FuelMonitoringPageState();
}

class _FuelMonitoringPageState extends State<FuelMonitoringPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _records = [];
  String _sort = 'Highest cost';
  StreamSubscription<List<Map<String, dynamic>>>? _recordsSubscription;

  @override
  void initState() {
    super.initState();
    _load();
    _recordsSubscription = Supabase.instance.client
        .from('refuel_records')
        .stream(primaryKey: ['id'])
        .listen(
          (_) => _load(showLoading: false),
          onError: (Object error) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Live fuel updates unavailable: $error')),
            );
          },
        );
  }

  @override
  void dispose() {
    _recordsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _load({bool showLoading = true}) async {
    if (showLoading && mounted) setState(() => _loading = true);
    try {
      final data = await Supabase.instance.client
          .from('refuel_records')
          .select(
            'total_cost, fuel_liters, odometer_km, vehicle_id, user_id, vehicles(brand, model, plate_number), users(full_name, username)',
          )
          .order('refuelled_at', ascending: false);
      _records = (data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to load monitoring data: $e')),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final record in _records) {
      groups
          .putIfAbsent('${record['user_id']}-${record['vehicle_id']}', () => [])
          .add(record);
    }

    final items = groups.values.map((records) {
      records.sort(
        (a, b) => ((a['odometer_km'] as num?) ?? 0).compareTo(
          (b['odometer_km'] as num?) ?? 0,
        ),
      );
      final first = records.first;
      final last = records.last;
      final fuel = records.fold(
        0.0,
        (sum, record) =>
            sum + ((record['fuel_liters'] as num?)?.toDouble() ?? 0),
      );
      final cost = records.fold(
        0.0,
        (sum, record) =>
            sum + ((record['total_cost'] as num?)?.toDouble() ?? 0),
      );
      final distance = records.length < 2
          ? 0.0
          : ((last['odometer_km'] as num).toDouble() -
                (first['odometer_km'] as num).toDouble());
      return {
        'first': first,
        'fuel': fuel,
        'cost': cost,
        'distance': distance,
        'efficiency': fuel == 0 ? 0.0 : distance / fuel,
      };
    }).toList();

    items.sort((a, b) {
      final key = _sort == 'Highest fuel'
          ? 'fuel'
          : _sort == 'Lowest efficiency'
          ? 'efficiency'
          : 'cost';
      final left = a[key] as double;
      final right = b[key] as double;
      return _sort == 'Lowest efficiency'
          ? left.compareTo(right)
          : right.compareTo(left);
    });

    return AdminShell(
      title: 'Fuel Monitoring',
      selectedRoute: AppRoutes.fuelMonitoring,
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: _load,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const _MonitoringHeader(),
                const SizedBox(height: 16),
                DropdownButtonFormField(
                  initialValue: _sort,
                  decoration: const InputDecoration(
                    labelText: 'Sort by',
                    prefixIcon: Icon(Icons.sort_rounded),
                  ),
                  items:
                      const [
                            'Highest cost',
                            'Highest fuel',
                            'Lowest efficiency',
                          ]
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                  onChanged: (value) => setState(() => _sort = value!),
                ),
                const SizedBox(height: 16),
                if (items.isEmpty)
                  const Center(child: Text('No fuel records found.'))
                else
                  ...items.map((item) {
                    final record = item['first'] as Map<String, dynamic>;
                    final vehicle = record['vehicles'] as Map<String, dynamic>?;
                    final user = record['users'] as Map<String, dynamic>?;
                    final driverName =
                        user?['full_name']?.toString().isNotEmpty == true
                        ? user!['full_name'].toString()
                        : user?['username']?.toString() ?? 'Employee';
                    final vehicleName =
                        '${vehicle?['brand'] ?? ''} ${vehicle?['model'] ?? ''}'
                            .trim();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _MonitoringCard(
                        driverName: driverName,
                        vehicleName: vehicleName.isEmpty
                            ? 'Unknown vehicle'
                            : vehicleName,
                        plateNumber: vehicle?['plate_number']?.toString() ?? '',
                        distanceKm: item['distance'] as double,
                        fuelLiters: item['fuel'] as double,
                        efficiency: item['efficiency'] as double,
                        cost: item['cost'] as double,
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}

class _MonitoringHeader extends StatelessWidget {
  const _MonitoringHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fuel Usage',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Compare driver fuel cost, litres used, and average efficiency.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF697079),
          ),
        ),
      ],
    );
  }
}

class _MonitoringCard extends StatelessWidget {
  final String driverName;
  final String vehicleName;
  final String plateNumber;
  final double distanceKm;
  final double fuelLiters;
  final double efficiency;
  final double cost;

  const _MonitoringCard({
    required this.driverName,
    required this.vehicleName,
    required this.plateNumber,
    required this.distanceKm,
    required this.fuelLiters,
    required this.efficiency,
    required this.cost,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withValues(
                    alpha: 0.12,
                  ),
                  foregroundColor: theme.colorScheme.primary,
                  child: const Icon(Icons.local_gas_station_outlined),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driverName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        plateNumber.isEmpty
                            ? vehicleName
                            : '$vehicleName - $plateNumber',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF697079),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'RM ${cost.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    label: 'Distance',
                    value: '${distanceKm.toStringAsFixed(1)} km',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricTile(
                    label: 'Fuel',
                    value: '${fuelLiters.toStringAsFixed(1)} L',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricTile(
                    label: 'Average',
                    value: '${efficiency.toStringAsFixed(2)} km/L',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;

  const _MetricTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: const Color(0xFF697079),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
