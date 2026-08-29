import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../routes/app_routes.dart';
import '../../admin/models/vehicle_model.dart';
import '../../admin/services/vehicle_service.dart';
import '../../home/widgets/driver_shell.dart';
import '../../fuel_price/services/fuel_price_service.dart';
import '../models/refuel_record_model.dart';
import '../services/fuel_calculator.dart';
import '../services/refuel_record_service.dart';

class RefuelRecordPage extends StatefulWidget {
  const RefuelRecordPage({super.key});
  @override
  State<RefuelRecordPage> createState() => _RefuelRecordPageState();
}

class _RefuelRecordPageState extends State<RefuelRecordPage> {
  final _form = GlobalKey<FormState>();
  final _odometer = TextEditingController();
  final _liters = TextEditingController();
  final _price = TextEditingController();
  final _station = TextEditingController();
  final _notes = TextEditingController();
  VehicleModel? _vehicle;
  bool _loading = true, _saving = false, _fullTank = true;
  DateTime _date = DateTime.now();
  String get _userId => Supabase.instance.client.auth.currentUser?.id ?? '';
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final controller in [_odometer, _liters, _price, _station, _notes]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      _vehicle = await VehicleService().loadAssignedVehicle(_userId);
      if (_vehicle != null &&
          FuelCalculator.supportsFuelType(_vehicle!.fuelType)) {
        _price.text = (await FuelPriceService().getCurrentPriceForFuelType(
          _vehicle!.fuelType,
        )).toStringAsFixed(2);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _number(String? value, {bool allowZero = false}) {
    final number = double.tryParse(value ?? '');
    return number == null || number < 0 || (!allowZero && number == 0)
        ? 'Enter a valid value'
        : null;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate() || _vehicle == null) return;
    setState(() => _saving = true);
    try {
      final liters = double.parse(_liters.text);
      final price = double.parse(_price.text);
      await RefuelRecordService().save(
        RefuelRecordModel(
          userId: _userId,
          vehicleId: _vehicle!.id,
          fuelType: _vehicle!.fuelType,
          date: _date,
          odometerKm: double.parse(_odometer.text),
          fuelLiters: liters,
          pricePerLiter: price,
          totalCost: liters * price,
          station: _station.text.trim(),
          isFullTank: _fullTank,
          notes: _notes.text.trim(),
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Refuel record saved.')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Unable to save: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const DriverShell(
        title: 'Add Refuel',
        selectedRoute: AppRoutes.refuelRecord,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return DriverShell(
      title: 'Add Refuel',
      selectedRoute: AppRoutes.refuelRecord,
      child: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              _vehicle == null
                  ? 'No assigned vehicle'
                  : '${_vehicle!.brand} ${_vehicle!.model}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Refuel Date'),
                      subtitle: Text(
                        '${_date.day}/${_date.month}/${_date.year}',
                      ),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) setState(() => _date = date);
                      },
                    ),
                    _field(_odometer, 'Odometer (km)'),
                    _field(_liters, 'Fuel Amount (L)'),
                    _field(_price, 'Price per Litre (RM)', allowZero: true),
                    TextFormField(
                      controller: _station,
                      decoration: const InputDecoration(
                        labelText: 'Fuel Station',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notes,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Notes'),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Full Tank'),
                      value: _fullTank,
                      onChanged: (value) => setState(() => _fullTank = value),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _vehicle == null || _saving ? null : _save,
              child: Text(_saving ? 'SAVING...' : 'SAVE REFUEL'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool allowZero = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
      validator: (value) => _number(value, allowZero: allowZero),
    ),
  );
}
