import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../routes/app_routes.dart';
import '../../home/widgets/driver_shell.dart';
import '../../user/database/local_database.dart';
import '../models/fuel_calculation_result.dart';

class FuelHistoryPage extends StatefulWidget {
  const FuelHistoryPage({super.key});
  @override
  State<FuelHistoryPage> createState() => _FuelHistoryPageState();
}

class _FuelHistoryPageState extends State<FuelHistoryPage> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _items = await LocalDatabase.instance.loadCalculations(
      userId: Supabase.instance.client.auth.currentUser?.id ?? '',
    );
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) => DriverShell(
    title: 'Fuel History',
    selectedRoute: AppRoutes.fuelHistory,
    child: _loading
        ? const Center(child: CircularProgressIndicator())
        : _items.isEmpty
        ? const Center(child: Text('No local calculations yet.'))
        : ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: _items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = _items[index];
              final result = FuelCalculationResult.fromHistoryMap(item);
              return Card(
                child: ListTile(
                  title: Text(result.vehicleDisplayName),
                  subtitle: Text(
                    '${result.createdAt.toLocal().toString().substring(0, 10)} • ${result.distanceKm.toStringAsFixed(1)} km • ${result.fuelUsedLiters.toStringAsFixed(2)} L',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'RM ${result.fuelCost.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          await LocalDatabase.instance.deleteCalculation(
                            item['id'] as int,
                          );
                          _load();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
  );
}
