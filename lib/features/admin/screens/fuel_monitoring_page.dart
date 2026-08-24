import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FuelMonitoringPage extends StatefulWidget {
  const FuelMonitoringPage({super.key});
  @override
  State<FuelMonitoringPage> createState() => _FuelMonitoringPageState();
}

class _FuelMonitoringPageState extends State<FuelMonitoringPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _records = [];
  String _sort = 'Highest cost';
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
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
      final first = records.first, last = records.last;
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
      final left = a[key] as double, right = b[key] as double;
      return _sort == 'Lowest efficiency'
          ? left.compareTo(right)
          : right.compareTo(left);
    });
    return Scaffold(
      appBar: AppBar(title: const Text('Fuel Monitoring')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                DropdownButtonFormField(
                  initialValue: _sort,
                  decoration: const InputDecoration(labelText: 'Sort by'),
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
                ...items.map((item) {
                  final record = item['first'] as Map<String, dynamic>;
                  final vehicle = record['vehicles'] as Map<String, dynamic>?;
                  final user = record['users'] as Map<String, dynamic>?;
                  return Card(
                    child: ListTile(
                      title: Text(
                        user?['full_name']?.toString().isNotEmpty == true
                            ? user!['full_name'].toString()
                            : user?['username']?.toString() ?? 'Employee',
                      ),
                      subtitle: Text(
                        '${vehicle?['brand'] ?? ''} ${vehicle?['model'] ?? ''}\nDistance: ${(item['distance'] as double).toStringAsFixed(1)} km • Fuel: ${(item['fuel'] as double).toStringAsFixed(1)} L\nAverage: ${(item['efficiency'] as double).toStringAsFixed(2)} km/L',
                      ),
                      trailing: Text(
                        'RM ${(item['cost'] as double).toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
