import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/models/user_model.dart';
import '../models/vehicle_model.dart';
import '../services/vehicle_service.dart';

class AddVehiclePage extends StatefulWidget {
  const AddVehiclePage({super.key});

  @override
  State<AddVehiclePage> createState() => _AddVehiclePageState();
}

class _AddVehiclePageState extends State<AddVehiclePage> {
  static const String _otherOption = 'Others';

  static const Map<String, List<String>> _modelsByBrand = {
    'Perodua': [
      'Axia',
      'Bezza',
      'Myvi',
      'Ativa',
      'Alza',
      'Aruz',
    ],
    'Proton': [
      'Saga',
      'Persona',
      'Iriz',
      'S70',
      'X50',
      'X70',
      'X90',
    ],
    'Toyota': [
      'Vios',
      'Yaris',
      'Corolla Altis',
      'Corolla Cross',
      'Camry',
      'Innova',
      'Fortuner',
      'Hilux',
      'Hiace',
    ],
    'Honda': [
      'City',
      'City Hatchback',
      'Civic',
      'Accord',
      'WR-V',
      'HR-V',
      'CR-V',
      'BR-V',
    ],
    'Nissan': [
      'Almera',
      'Serena',
      'Navara',
      'X-Trail',
      'NV200',
      'Urvan',
    ],
    'Mitsubishi': [
      'Triton',
      'Xpander',
      'Outlander',
      'Pajero Sport',
    ],
    'Isuzu': [
      'D-Max',
      'MU-X',
      'N-Series',
      'F-Series',
    ],
    'Mazda': [
      'Mazda 2',
      'Mazda 3',
      'Mazda 6',
      'CX-3',
      'CX-5',
      'CX-8',
      'CX-30',
      'BT-50',
    ],
    'Hyundai': [
      'Accent',
      'Elantra',
      'Kona',
      'Tucson',
      'Santa Fe',
      'Staria',
      'H-1',
    ],
    'Kia': [
      'Picanto',
      'Cerato',
      'Seltos',
      'Sportage',
      'Sorento',
      'Carnival',
    ],
    'Ford': [
      'Ranger',
      'Everest',
      'Transit',
    ],
    'Mercedes-Benz': [
      'A-Class',
      'C-Class',
      'E-Class',
      'GLA',
      'GLC',
      'Sprinter',
      'Vito',
    ],
    'BMW': [
      '1 Series',
      '2 Series',
      '3 Series',
      '5 Series',
      'X1',
      'X3',
      'X5',
    ],
    'Volkswagen': [
      'Polo',
      'Vento',
      'Passat',
      'Tiguan',
      'Golf',
      'Caddy',
    ],
    'Subaru': [
      'XV',
      'Forester',
      'Outback',
      'WRX',
    ],
    'Suzuki': [
      'Swift',
      'Jimny',
      'Vitara',
      'Carry',
    ],
    'Hino': [
      '300 Series',
      '500 Series',
      '700 Series',
    ],
    'Fuso': [
      'Canter',
      'Fighter',
    ],
    'UD Trucks': [
      'Kuzer',
      'Croner',
      'Quester',
    ],
    'Volvo': [
      'XC40',
      'XC60',
      'XC90',
      'FM',
      'FH',
    ],
    'Tesla': [
      'Model 3',
      'Model Y',
      'Model S',
      'Model X',
    ],
    'BYD': [
      'Atto 3',
      'Dolphin',
      'Seal',
      'M6',
    ],
    'Chery': [
      'Omoda 5',
      'Tiggo 7 Pro',
      'Tiggo 8 Pro',
    ],
    'GWM': [
      'Haval H6',
      'Ora Good Cat',
      'Tank 300',
      'Cannon',
    ],
    _otherOption: [_otherOption],
  };

  static const List<String> _fuelTypes = [
    'RON95',
    'RON97',
    'Diesel',
    'Electric',
    'Hybrid',
  ];

  static const List<String> _statuses = [
    'Available',
    'Maintenance',
    'Inactive',
  ];

  final _formKey = GlobalKey<FormState>();
  final _plateController = TextEditingController();
  final _customBrandController = TextEditingController();
  final _customModelController = TextEditingController();
  final _fuelEfficiencyController = TextEditingController();
  final _tankCapacityController = TextEditingController();
  final _notesController = TextEditingController();
  final _vehicleService = VehicleService();

  List<UserModel> _employees = [];
  String _brand = 'Perodua';
  String _model = 'Axia';
  String _fuelType = _fuelTypes.first;
  String _status = _statuses.first;
  String? _assignedUserId;
  bool _isLoadingVehicleSpec = false;
  bool _isLoadingEmployees = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
    _applyVehicleSpec(brand: _brand, model: _model);
  }

  @override
  void dispose() {
    _plateController.dispose();
    _customBrandController.dispose();
    _customModelController.dispose();
    _fuelEfficiencyController.dispose();
    _tankCapacityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    try {
      final employees = await _vehicleService.loadEmployees();
      if (!mounted) return;

      setState(() {
        _employees = employees;
        _isLoadingEmployees = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoadingEmployees = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load driver accounts.')),
      );
    }
  }

  Future<void> _applyVehicleSpec({
    required String brand,
    required String model,
  }) async {
    if (brand == _otherOption || model == _otherOption) {
      if (mounted) {
        setState(() {
          _isLoadingVehicleSpec = false;
        });
      }
      return;
    }

    setState(() {
      _isLoadingVehicleSpec = true;
    });

    try {
      final spec = await _vehicleService.getVehicleSpec(
        brand: brand,
        model: model,
      );
      if (!mounted) return;

      if (brand != _brand || model != _model) {
        setState(() {
          _isLoadingVehicleSpec = false;
        });
        return;
      }

      if (spec == null) {
        setState(() {
          _isLoadingVehicleSpec = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No default specs found for $brand $model. Run vehicle_specs_seed.sql in Supabase.',
            ),
          ),
        );
        return;
      }

      final fuelEfficiency = spec.defaultFuelEfficiencyKmPerLiter;
      final tankCapacity = spec.defaultTankCapacityLiters;

      setState(() {
        _fuelType = _fuelTypes.contains(spec.defaultFuelType)
            ? spec.defaultFuelType
            : _fuelType;
        if (fuelEfficiency != null) {
          _fuelEfficiencyController.text = _formatNumber(fuelEfficiency);
        }
        if (tankCapacity != null) {
          _tankCapacityController.text = _formatNumber(tankCapacity);
        }
        _isLoadingVehicleSpec = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingVehicleSpec = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to load default specs: $e')),
      );
    }
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final assignedUserId = _assignedUserId;
    final vehicleBrand = _brand == _otherOption
        ? _customBrandController.text.trim()
        : _brand;
    final vehicleModel = _model == _otherOption
        ? _customModelController.text.trim()
        : _model;
    final vehicle = VehicleModel(
      plateNumber: _plateController.text.trim().toUpperCase(),
      brand: vehicleBrand,
      model: vehicleModel,
      fuelType: _fuelType,
      fuelEfficiencyKmPerLiter: double.parse(
        _fuelEfficiencyController.text.trim(),
      ),
      tankCapacityLiters: double.parse(_tankCapacityController.text.trim()),
      assignedUserId: assignedUserId,
      status: assignedUserId == null ? _status : 'Assigned',
      notes: _notesController.text.trim(),
    );

    try {
      await _vehicleService.addVehicle(vehicle);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehicle added successfully.')),
      );
      Navigator.of(context).pop();
    } on PostgrestException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String? _requiredText(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  String? _positiveNumber(String? value, String label) {
    final number = double.tryParse(value?.trim() ?? '');
    if (number == null) {
      return '$label must be a number';
    }
    if (number <= 0) {
      return '$label must be more than 0';
    }
    return null;
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final models = _modelsByBrand[_brand]!.contains(_otherOption)
        ? _modelsByBrand[_brand]!
        : [..._modelsByBrand[_brand]!, _otherOption];
    final isCustomBrand = _brand == _otherOption;
    final isCustomModel = _model == _otherOption;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Vehicle',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: theme.colorScheme.onBackground,
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Vehicle Details',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                'Use fixed choices where possible to keep fleet records clean.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _plateController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Plate Number',
                          hintText: 'Example: VAB1234',
                          prefixIcon: Icon(Icons.confirmation_number_outlined),
                        ),
                        validator: (value) =>
                            _requiredText(value, 'Plate number'),
                      ),
                      const SizedBox(height: 16),
                      _DropdownField<String>(
                        label: 'Brand',
                        icon: Icons.directions_car_outlined,
                        value: _brand,
                        items: _modelsByBrand.keys.toList(),
                        itemLabel: (value) => value,
                        onChanged: (value) {
                          if (value == null) return;
                          final nextModel = _modelsByBrand[value]!.first;
                          setState(() {
                            _brand = value;
                            _model = nextModel;
                            if (value != _otherOption) {
                              _customBrandController.clear();
                            }
                            _customModelController.clear();
                          });
                          _applyVehicleSpec(brand: value, model: nextModel);
                        },
                      ),
                      if (isCustomBrand) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _customBrandController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Custom Brand',
                            hintText: 'Enter vehicle brand',
                            prefixIcon: Icon(Icons.edit_outlined),
                          ),
                          validator: (value) =>
                              _requiredText(value, 'Custom brand'),
                        ),
                      ],
                      const SizedBox(height: 16),
                      _DropdownField<String>(
                        label: 'Model',
                        icon: Icons.badge_outlined,
                        value: _model,
                        items: models,
                        itemLabel: (value) => value,
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _model = value;
                            if (value != _otherOption) {
                              _customModelController.clear();
                            }
                          });
                          _applyVehicleSpec(brand: _brand, model: value);
                        },
                      ),
                      if (isCustomModel) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _customModelController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Custom Model',
                            hintText: 'Enter vehicle model',
                            prefixIcon: Icon(Icons.edit_note_outlined),
                          ),
                          validator: (value) =>
                              _requiredText(value, 'Custom model'),
                        ),
                      ],
                      const SizedBox(height: 16),
                      _DropdownField<String>(
                        label: 'Fuel Type',
                        icon: Icons.local_gas_station_outlined,
                        value: _fuelType,
                        items: _fuelTypes,
                        itemLabel: (value) => value,
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _fuelType = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _fuelEfficiencyController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: _isLoadingVehicleSpec
                              ? 'Loading Fuel Efficiency...'
                              : 'Fuel Efficiency (km/L)',
                          hintText: 'Example: 14.5',
                          prefixIcon: const Icon(Icons.speed_outlined),
                        ),
                        validator: (value) =>
                            _positiveNumber(value, 'Fuel efficiency'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _tankCapacityController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: _isLoadingVehicleSpec
                              ? 'Loading Tank Capacity...'
                              : 'Tank Capacity (L)',
                          hintText: 'Example: 45',
                          prefixIcon: const Icon(Icons.water_drop_outlined),
                        ),
                        validator: (value) =>
                            _positiveNumber(value, 'Tank capacity'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _DropdownField<String>(
                        label: 'Assign To Driver',
                        icon: Icons.person_add_alt_outlined,
                        value: _assignedUserId ?? '',
                        items: ['', ..._employees.map((user) => user.id)],
                        itemLabel: (value) {
                          if (_isLoadingEmployees) {
                            return 'Loading drivers...';
                          }
                          if (value.isEmpty) {
                            return 'Unassigned';
                          }

                          final driver = _employees.firstWhere(
                            (user) => user.id == value,
                          );
                          final name = driver.fullName.trim().isEmpty
                              ? driver.username
                              : driver.fullName;
                          return '$name (${driver.email})';
                        },
                        onChanged: _isLoadingEmployees
                            ? null
                            : (value) {
                                setState(() {
                                  _assignedUserId = value?.isEmpty == true
                                      ? null
                                      : value;
                                });
                              },
                      ),
                      const SizedBox(height: 16),
                      _DropdownField<String>(
                        label: 'Vehicle Status',
                        icon: Icons.verified_outlined,
                        value: _assignedUserId == null ? _status : 'Assigned',
                        items: _assignedUserId == null
                            ? _statuses
                            : const ['Assigned'],
                        itemLabel: (value) => value,
                        onChanged: _assignedUserId != null
                            ? null
                            : (value) {
                                if (value == null) return;
                                setState(() {
                                  _status = value;
                                });
                              },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        minLines: 3,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                          hintText: 'Optional vehicle remarks',
                          prefixIcon: Icon(Icons.notes_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveVehicle,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('ADD VEHICLE'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final IconData icon;
  final T value;
  final List<T> items;
  final String Function(T value) itemLabel;
  final ValueChanged<T?>? onChanged;

  const _DropdownField({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(
                itemLabel(item),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
