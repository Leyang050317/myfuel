import 'package:flutter/material.dart';

import '../../../routes/app_routes.dart';
import '../../auth/models/user_model.dart';
import '../models/vehicle_model.dart';
import '../services/vehicle_service.dart';
import '../widgets/admin_shell.dart';

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
  final Set<String> _selectedVehicleIds = {};
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isDeleting = false;

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
        _selectedVehicleIds.removeWhere(
          (id) => vehicles.every((vehicle) => vehicle.id != id),
        );
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to load vehicles: $e')));
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

  VehicleModel? _otherVehicleAssignedTo(
    String driverId,
    String currentVehicleId,
  ) {
    for (final vehicle in _vehicles) {
      if (vehicle.id != currentVehicleId &&
          vehicle.assignedUserId == driverId &&
          !vehicle.isDeleted) {
        return vehicle;
      }
    }
    return null;
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        _selectedVehicleIds.clear();
      }
    });
  }

  void _toggleVehicleSelection(String vehicleId, bool selected) {
    setState(() {
      if (selected) {
        _selectedVehicleIds.add(vehicleId);
      } else {
        _selectedVehicleIds.remove(vehicleId);
      }
    });
  }

  Future<void> _deleteSelectedVehicles() async {
    if (_selectedVehicleIds.isEmpty || _isDeleting) {
      return;
    }

    final count = _selectedVehicleIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete vehicles?'),
        content: Text(
          count == 1
              ? 'This vehicle will be removed from active vehicle lists.'
              : '$count vehicles will be removed from active vehicle lists.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      await _vehicleService.deleteVehicles(_selectedVehicleIds.toList());
      if (!mounted) return;

      setState(() {
        _selectedVehicleIds.clear();
        _isEditing = false;
      });
      await _loadData();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            count == 1 ? 'Vehicle deleted.' : '$count vehicles deleted.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to delete vehicles: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
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
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedDriverId ?? '',
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
                        ..._drivers.map((driver) {
                          final name = driver.fullName.trim().isEmpty
                              ? driver.username
                              : driver.fullName;
                          final otherVehicle = _otherVehicleAssignedTo(
                            driver.id,
                            vehicle.id,
                          );
                          return DropdownMenuItem<String>(
                            value: driver.id,
                            enabled: otherVehicle == null,
                            child: Text(
                              otherVehicle == null
                                  ? '$name (${driver.email})'
                                  : '$name - assigned to ${otherVehicle.plateNumber}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
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
                      initialValue: selectedStatus,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Vehicle Status',
                        prefixIcon: Icon(Icons.verified_outlined),
                      ),
                      items:
                          (selectedDriverId == null
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
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
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
                                  if (!context.mounted || !mounted) return;

                                  Navigator.of(context).pop();
                                  await _loadData();
                                  if (!mounted) return;

                                  ScaffoldMessenger.of(
                                    this.context,
                                  ).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Vehicle assignment updated.',
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  if (!context.mounted || !mounted) return;
                                  setSheetState(() {
                                    isSaving = false;
                                  });
                                  ScaffoldMessenger.of(
                                    this.context,
                                  ).showSnackBar(
                                    SnackBar(
                                      content: Text('Unable to update: $e'),
                                    ),
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

    return AdminShell(
      title: 'Manage Vehicle',
      selectedRoute: AppRoutes.manageVehicles,
      actions: [
        if (_isEditing && _selectedVehicleIds.isNotEmpty)
          IconButton(
            tooltip: 'Delete selected vehicles',
            onPressed: _isDeleting ? null : _deleteSelectedVehicles,
            icon: _isDeleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFD32F2F),
                  ),
          ),
        IconButton(
          tooltip: _isEditing ? 'Done' : 'Edit',
          onPressed: _isDeleting ? null : _toggleEditMode,
          icon: Icon(_isEditing ? Icons.check_rounded : Icons.edit_outlined),
        ),
      ],
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
              itemCount: _vehicles.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _ManageVehicleHeader(
                    vehicleCount: _vehicles.length,
                    selectedCount: _selectedVehicleIds.length,
                    isEditing: _isEditing,
                  );
                }

                final vehicle = _vehicles[index - 1];
                final assignedDriver = _driverName(vehicle.assignedUserId);

                return _VehicleCard(
                  vehicle: vehicle,
                  assignedDriver: assignedDriver,
                  isEditing: _isEditing,
                  isSelected: _selectedVehicleIds.contains(vehicle.id),
                  onSelectionChanged: (selected) =>
                      _toggleVehicleSelection(vehicle.id, selected),
                  onEdit: _isEditing
                      ? null
                      : () => _showEditAssignmentSheet(vehicle),
                );
              },
            ),
    );
  }
}

class _ManageVehicleHeader extends StatelessWidget {
  final int vehicleCount;
  final int selectedCount;
  final bool isEditing;

  const _ManageVehicleHeader({
    required this.vehicleCount,
    required this.selectedCount,
    required this.isEditing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vehicle Assignments',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Check who is using each company vehicle and update assignment.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF697079),
                  ),
                ),
              ],
            ),
          ),
          _CountPill(
            label: isEditing
                ? '$selectedCount selected'
                : '$vehicleCount vehicles',
          ),
        ],
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  final String label;

  const _CountPill({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final VehicleModel vehicle;
  final String assignedDriver;
  final bool isEditing;
  final bool isSelected;
  final ValueChanged<bool> onSelectionChanged;
  final VoidCallback? onEdit;

  const _VehicleCard({
    required this.vehicle,
    required this.assignedDriver,
    required this.isEditing,
    required this.isSelected,
    required this.onSelectionChanged,
    required this.onEdit,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'Assigned':
        return const Color(0xFF1976D2);
      case 'Maintenance':
        return const Color(0xFFFFA000);
      case 'Inactive':
        return const Color(0xFF697079);
      default:
        return const Color(0xFF2E7D32);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(vehicle.status);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: isEditing ? () => onSelectionChanged(!isSelected) : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.colorScheme.primary.withValues(
                      alpha: 0.12,
                    ),
                    foregroundColor: theme.colorScheme.primary,
                    child: const Icon(Icons.directions_car_outlined),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle.plateNumber,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${vehicle.brand} ${vehicle.model}',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFF697079),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusChip(label: vehicle.status, color: statusColor),
                  const SizedBox(width: 4),
                  if (isEditing)
                    Checkbox(
                      value: isSelected,
                      onChanged: (value) => onSelectionChanged(value ?? false),
                    )
                  else
                    IconButton(
                      tooltip: 'Edit assignment',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: onEdit,
                    ),
                ],
              ),
              const SizedBox(height: 14),
              _InfoBlock(
                icon: Icons.person_outline_rounded,
                label: 'Assigned To',
                value: assignedDriver,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _InfoBlock(
                      icon: Icons.local_gas_station_outlined,
                      label: 'Fuel Type',
                      value: vehicle.fuelType,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _InfoBlock(
                      icon: Icons.water_drop_outlined,
                      label: 'Tank',
                      value:
                          '${vehicle.tankCapacityLiters.toStringAsFixed(0)} L',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoBlock({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(8),
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
                    color: const Color(0xFF697079),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
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
