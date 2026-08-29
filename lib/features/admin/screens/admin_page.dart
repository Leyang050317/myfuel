import 'package:flutter/material.dart';

import '../../../routes/app_routes.dart';
import '../../fuel_tracking/models/fuel_claim_model.dart';
import '../../fuel_tracking/services/fuel_claim_service.dart';
import '../models/vehicle_model.dart';
import '../services/vehicle_service.dart';
import '../widgets/admin_shell.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _vehicleService = VehicleService();
  final _fuelClaimService = FuelClaimService();

  List<VehicleModel> _vehicles = [];
  List<FuelClaimModel> _claims = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final vehicles = await _vehicleService.loadVehicles();
      final claims = await _fuelClaimService.loadClaims();

      if (!mounted) return;

      setState(() {
        _vehicles = vehicles;
        _claims = claims;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to load dashboard: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Admin Dashboard',
      selectedRoute: AppRoutes.admin,
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: _loadDashboard,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _AdminDashboardContent(vehicles: _vehicles, claims: _claims),
    );
  }
}

class _AdminDashboardContent extends StatelessWidget {
  final List<VehicleModel> vehicles;
  final List<FuelClaimModel> claims;

  const _AdminDashboardContent({required this.vehicles, required this.claims});

  @override
  Widget build(BuildContext context) {
    final assignedVehicles = vehicles
        .where((vehicle) => vehicle.assignedUserId?.isNotEmpty == true)
        .length;
    final availableVehicles = vehicles
        .where((vehicle) => vehicle.status == 'Available')
        .length;
    final pendingClaims = claims
        .where((claim) => claim.status == 'Pending')
        .length;
    final attentionItems = _buildAttentionItems(
      vehicles: vehicles,
      claims: claims,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape =
            MediaQuery.orientationOf(context) == Orientation.landscape;
        final isCompactLandscape = isLandscape && constraints.maxWidth >= 520;
        final isWide = constraints.maxWidth >= 960;
        final columnCount = isCompactLandscape || isWide ? 4 : 2;
        final pagePadding = isCompactLandscape ? 16.0 : 24.0;

        return ListView(
          padding: EdgeInsets.all(pagePadding),
          children: [
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: columnCount,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: isCompactLandscape ? 108 : null,
              childAspectRatio: isWide ? 1.35 : 1.15,
              children: [
                _SummaryCard(
                  label: 'Total Vehicles',
                  value: vehicles.length.toString(),
                  icon: Icons.directions_car_outlined,
                  color: const Color(0xFFD32F2F),
                  compact: isCompactLandscape,
                ),
                _SummaryCard(
                  label: 'Assigned',
                  value: assignedVehicles.toString(),
                  icon: Icons.assignment_ind_outlined,
                  color: const Color(0xFF1976D2),
                  compact: isCompactLandscape,
                ),
                _SummaryCard(
                  label: 'Available',
                  value: availableVehicles.toString(),
                  icon: Icons.verified_outlined,
                  color: const Color(0xFF2E7D32),
                  compact: isCompactLandscape,
                ),
                _SummaryCard(
                  label: 'Pending Claims',
                  value: pendingClaims.toString(),
                  icon: Icons.payments_outlined,
                  color: const Color(0xFFFFA000),
                  compact: isCompactLandscape,
                ),
              ],
            ),
            SizedBox(height: isCompactLandscape ? 16 : 24),
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: isWide ? 520 : double.infinity,
                child: _DashboardPanel(
                  title: 'Pending Tasks',
                  emptyText: 'No pending tasks right now.',
                  items: attentionItems,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<_DashboardListItem> _buildAttentionItems({
    required List<VehicleModel> vehicles,
    required List<FuelClaimModel> claims,
  }) {
    final unassignedCount = vehicles
        .where((vehicle) => vehicle.assignedUserId?.isNotEmpty != true)
        .length;
    final maintenanceCount = vehicles
        .where((vehicle) => vehicle.status == 'Maintenance')
        .length;
    final pendingClaimsCount = claims
        .where((claim) => claim.status == 'Pending')
        .length;

    return [
      if (pendingClaimsCount > 0)
        _DashboardListItem(
          icon: Icons.payments_outlined,
          title: '$pendingClaimsCount fuel claims pending',
          subtitle: 'Review driver fuel claims.',
          color: const Color(0xFFFFA000),
        ),
      if (unassignedCount > 0)
        _DashboardListItem(
          icon: Icons.person_off_outlined,
          title: '$unassignedCount vehicles unassigned',
          subtitle: 'Assign vehicles to driver accounts.',
          color: const Color(0xFF1976D2),
        ),
      if (maintenanceCount > 0)
        _DashboardListItem(
          icon: Icons.build_outlined,
          title: '$maintenanceCount vehicles under maintenance',
          subtitle: 'Check vehicle availability before assigning.',
          color: const Color(0xFFD32F2F),
        ),
    ];
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool compact;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 16),
        child: compact
            ? Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: color.withValues(alpha: 0.12),
                    foregroundColor: color,
                    child: Icon(icon, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: _buildDetails(theme)),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.12),
                    foregroundColor: color,
                    child: Icon(icon),
                  ),
                  _buildDetails(theme),
                ],
              ),
      ),
    );
  }

  Widget _buildDetails(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF697079),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _DashboardPanel extends StatelessWidget {
  final String title;
  final String emptyText;
  final List<_DashboardListItem> items;

  const _DashboardPanel({
    required this.title,
    required this.emptyText,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            if (items.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  emptyText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF697079),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _DashboardListTile(item: item),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DashboardListTile extends StatelessWidget {
  final _DashboardListItem item;

  const _DashboardListTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: item.color.withValues(alpha: 0.12),
            foregroundColor: item.color,
            child: Icon(item.icon, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF697079),
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

class _DashboardListItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _DashboardListItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}
