import 'package:flutter/material.dart';

import '../../auth/models/user_model.dart';
import '../models/vehicle_model.dart';
import '../services/vehicle_service.dart';

class ManageVehiclesPage extends StatefulWidget {
  const ManageVehiclesPage({super.key});

  @override
  State<ManageVehiclesPage> createState() => _ManageVehiclesPageState();
}

class _ManageVehiclesPageState extends State<ManageVehiclesPage> {
  static const List<String> _statuses = [
    'Available',
    'Maintenance',
    'Inactive',
  ];

  final _vehicleService = VehicleService();

  List<VehicleModel> _vehicles = [];
  List<UserModel> _drivers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final vehicles = await _vehicleService.loadVehicles();
      final drivers = await _vehicleService.loadEmployees();

      if (!mounted) return;

      setState(() {
        _vehicles = vehicles;
        _drivers = drivers;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to load vehicles: $e')),
      );
    }
  }

  String _driverName(String? driverId) {
    if (driverId == null || driverId.isEmpty) {
      return 'Unassigned';
    }

    final driver = _findDriver(driverId);
    if (driver == null) {
      return 'Unknown driver';
    }

    final name = driver.fullName.trim().isEmpty
        ? driver.username
        : driver.fullName;
    return '$name (${driver.email})';
  }

  UserModel? _findDriver(String driverId) {
    for (final driver in _drivers) {
      if (driver.id == driverId) {
        return driver;
      }
    }
    return null;
  }

  Future<void> _showEditAssignmentSheet(VehicleModel vehicle) async {
    String? selectedDriverId = vehicle.assignedUserId;
    String selectedStatus = vehicle.assignedUserId == null
        ? vehicle.status
        : 'Assigned';
    bool isSaving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final theme = Theme.of(context);

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${vehicle.plateNumber} - ${vehicle.brand} ${vehicle.model}',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedDriverId ?? '',
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Assign To Driver',
                        prefixIcon: Icon(Icons.person_add_alt_outlined),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: '',
                          child: Text('Unassigned'),
                        ),
                        ..._drivers.map(
                          (driver) {
                            final name = driver.fullName.trim().isEmpty
                                ? driver.username
                                : driver.fullName;
                            return DropdownMenuItem<String>(
                              value: driver.id,
                              child: Text(
                                '$name (${driver.email})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          },
                        ),
                      ],
                      onChanged: (value) {
                        setSheetState(() {
                          selectedDriverId = value?.isEmpty == true
                              ? null
                              : value;
                          selectedStatus = selectedDriverId == null
                              ? _statuses.first
                              : 'Assigned';
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Vehicle Status',
                        prefixIcon: Icon(Icons.verified_outlined),
                      ),
                      items: (selectedDriverId == null
                              ? _statuses
                              : const ['Assigned'])
                          .map(
                            (status) => DropdownMenuItem<String>(
                              value: status,
                              child: Text(status),
                            ),
                          )
                          .toList(),
                      onChanged: selectedDriverId != null
                          ? null
                          : (value) {
                              if (value == null) return;
                              setSheetState(() {
                                selectedStatus = value;
                              });
                            },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              setSheetState(() {
                                isSaving = true;
                              });

                              try {
                                await _vehicleService.updateVehicleAssignment(
                                  vehicleId: vehicle.id,
                                  assignedUserId: selectedDriverId,
                                  status: selectedStatus,
                                );
                                if (!mounted) return;

                                Navigator.of(context).pop();
                                await _loadData();
                                if (!mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Vehicle assignment updated.'),
                                  ),
                                );
                              } catch (e) {
                                setSheetState(() {
                                  isSaving = false;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Unable to update: $e')),
                                );
                              }
                            },
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('SAVE CHANGES'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manage Vehicles',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: theme.colorScheme.onBackground,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _vehicles.isEmpty
                ? Center(
                    child: Text(
                      'No vehicles added yet.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: _vehicles.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final vehicle = _vehicles[index];
                      final assignedDriver = _driverName(vehicle.assignedUserId);

                      return Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: theme.colorScheme.primary
                                        .withOpacity(0.12),
                                    foregroundColor: theme.colorScheme.primary,
                                    child: const Icon(
                                      Icons.directions_car_outlined,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          vehicle.plateNumber,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${vehicle.brand} ${vehicle.model}',
                                          style: theme.textTheme.bodyLarge
                                              ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Edit assignment',
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () =>
                                        _showEditAssignmentSheet(vehicle),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _InfoRow(
                                icon: Icons.person_outline_rounded,
                                label: 'Assigned To',
                                value: assignedDriver,
                              ),
                              const SizedBox(height: 10),
                              _InfoRow(
                                icon: Icons.verified_outlined,
                                label: 'Status',
                                value: vehicle.status,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
