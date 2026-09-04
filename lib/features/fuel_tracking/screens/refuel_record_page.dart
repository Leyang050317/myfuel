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

  bool _loading = true;
  bool _saving = false;
  bool _fullTank = true;

  DateTime _date = DateTime.now();

  String get _userId =>
      Supabase.instance.client.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _odometer.dispose();
    _liters.dispose();
    _price.dispose();
    _station.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      _vehicle = await VehicleService().loadAssignedVehicle(_userId);

      if (_vehicle != null &&
          FuelCalculator.supportsFuelType(_vehicle!.fuelType)) {
        _price.text =
            (await FuelPriceService().getCurrentPriceForFuelType(
              _vehicle!.fuelType,
            ))
                .toStringAsFixed(2);
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  String? _number(
      String? value, {
        bool allowZero = false,
        bool wholeNumber = false,
        required double max,
        required String fieldName,
      }) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return '$fieldName is required';
    }

    final number = double.tryParse(text);

    if (number == null || number.isNaN || number.isInfinite) {
      return 'Enter a valid $fieldName';
    }

    if (number < 0) {
      return '$fieldName cannot be negative';
    }

    if (!allowZero && number == 0) {
      return '$fieldName must be greater than 0';
    }

    if (wholeNumber && number != number.truncateToDouble()) {
      return '$fieldName must be a whole number';
    }

    if (number > max) {
      return wholeNumber
          ? '$fieldName cannot exceed ${max.toInt()}'
          : '$fieldName cannot exceed ${max.toStringAsFixed(2)}';
    }

    return null;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) {
      return;
    }

    if (_vehicle == null) {
      _showMessage('No assigned vehicle found.');
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final odometer = double.parse(_odometer.text.trim());
      final liters = double.parse(_liters.text.trim());
      final price = double.parse(_price.text.trim());

      final totalCost = liters * price;

      if (totalCost > 9999999999.99) {
        _showMessage(
          'Total fuel cost is too large. Please check the fuel amount and price.',
        );
        return;
      }

      await RefuelRecordService().save(
        RefuelRecordModel(
          userId: _userId,
          vehicleId: _vehicle!.id,
          fuelType: _vehicle!.fuelType,
          date: _date,
          odometerKm: odometer,
          fuelLiters: liters,
          pricePerLiter: price,
          totalCost: totalCost,
          station: _station.text.trim(),
          isFullTank: _fullTank,
          notes: _notes.text.trim(),
        ),
      );

      if (mounted) {
        _form.currentState?.reset();

        _odometer.clear();
        _liters.clear();
        _station.clear();
        _notes.clear();

        if (_vehicle != null &&
            FuelCalculator.supportsFuelType(_vehicle!.fuelType)) {
          _price.text =
              (await FuelPriceService().getCurrentPriceForFuelType(
                _vehicle!.fuelType,
              ))
                  .toStringAsFixed(2);
        } else {
          _price.clear();
        }

        setState(() {
          _date = DateTime.now();
          _fullTank = true;
        });

        _showMessage(
          'Refuel record saved successfully.',
        );
      }
    } on ArgumentError catch (e) {
      if (mounted) {
        _showMessage(
          e.message.toString(),
        );
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        _showDatabaseError(e);
      }
    } catch (e) {
      if (mounted) {
        _showMessage(
          'Unable to save the refuel record. Please check your values and try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  void _showDatabaseError(PostgrestException error) {
    String message =
        'Unable to save the refuel record. Please check your values.';

    final details = '${error.message} ${error.details ?? ''}'.toLowerCase();

    if (details.contains('numeric field overflow') ||
        details.contains('precision') ||
        details.contains('overflow')) {
      message =
      'One of the entered values is too large. Please enter a smaller value.';
    } else if (details.contains('violates check constraint')) {
      message =
      'One of the entered values is not valid. Please check the form.';
    } else if (details.contains('duplicate')) {
      message =
      'This refuel record already exists.';
    }

    _showMessage(message);
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const DriverShell(
        title: 'Add Refuel',
        selectedRoute: AppRoutes.refuelRecord,
        child: Center(
          child: CircularProgressIndicator(),
        ),
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

                        if (date != null) {
                          setState(() {
                            _date = date;
                          });
                        }
                      },
                    ),
                    _field(
                      _odometer,
                      'Odometer (km)',
                      fieldName: 'Odometer',
                      max: 9999999999,
                      wholeNumber: true,
                    ),
                    _field(
                      _liters,
                      'Fuel Amount (L)',
                      fieldName: 'Fuel amount',
                      max: 99999999.99,
                    ),
                    _field(
                      _price,
                      'Price per Litre (RM)',
                      fieldName: 'Price per litre',
                      allowZero: true,
                      max: 99999999.99,
                    ),
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
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Full Tank'),
                      value: _fullTank,
                      onChanged: (value) {
                        setState(() {
                          _fullTank = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed:
              _vehicle == null || _saving ? null : _save,
              child: Text(
                _saving ? 'SAVING...' : 'SAVE REFUEL',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
      TextEditingController controller,
      String label, {
        required String fieldName,
        required double max,
        bool allowZero = false,
        bool wholeNumber = false,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: false,
        ),
        decoration: InputDecoration(
          labelText: label,
        ),
        validator: (value) => _number(
          value,
          allowZero: allowZero,
          wholeNumber: wholeNumber,
          max: max,
          fieldName: fieldName,
        ),
      ),
    );
  }
}