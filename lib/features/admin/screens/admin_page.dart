import 'package:flutter/material.dart';

import '../../../routes/app_routes.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  void _logout(BuildContext context) {
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showSidebar = MediaQuery.of(context).size.width >= 720;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        leading: showSidebar
            ? null
            : Builder(
                builder: (context) {
                  return IconButton(
                    tooltip: 'Menu',
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                    icon: const Icon(Icons.menu_rounded),
                  );
                },
              ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: showSidebar
          ? null
          : Drawer(
              child: _AdminSidebar(
                onLogout: () => _logout(context),
                showTopSpacer: true,
              ),
            ),
      body: SafeArea(
        child: Row(
          children: [
            if (showSidebar)
              SizedBox(
                width: 260,
                child: _AdminSidebar(onLogout: () => _logout(context)),
              ),
            if (showSidebar) const VerticalDivider(width: 1),
            const Expanded(child: _AdminDashboardContent()),
          ],
        ),
      ),
    );
  }
}

class _AdminSidebar extends StatelessWidget {
  final VoidCallback onLogout;
  final bool showTopSpacer;

  const _AdminSidebar({required this.onLogout, this.showTopSpacer = false});

  void _closeDrawerIfOpen(BuildContext context) {
    if (Scaffold.maybeOf(context)?.isDrawerOpen == true) {
      Navigator.of(context).pop();
    }
  }

  void _openRoute(BuildContext context, String routeName) {
    _closeDrawerIfOpen(context);
    Navigator.of(context).pushNamed(routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          showTopSpacer ? kToolbarHeight + 50 : 18,
          16,
          16,
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _SidebarItem(
                    icon: Icons.dashboard_outlined,
                    label: 'Dashboard',
                    selected: true,
                    onTap: () {
                      _closeDrawerIfOpen(context);
                    },
                  ),
                  _SidebarItem(
                    icon: Icons.add_road_outlined,
                    label: 'Add Vehicle',
                    onTap: () {
                      _openRoute(context, AppRoutes.addVehicle);
                    },
                  ),
                  _SidebarItem(
                    icon: Icons.assignment_ind_outlined,
                    label: 'Manage Vehicle',
                    onTap: () {
                      _openRoute(context, AppRoutes.manageVehicles);
                    },
                  ),
                  _SidebarItem(
                    icon: Icons.payments_outlined,
                    label: 'Fuel Claims',
                    onTap: () {
                      _openRoute(context, AppRoutes.fuelClaims);
                    },
                  ),
                  _SidebarItem(
                    icon: Icons.insights_outlined,
                    label: 'Fuel Monitoring',
                    onTap: () => _openRoute(context, AppRoutes.fuelMonitoring),
                  ),
                  _SidebarItem(
                    icon: Icons.location_on_outlined,
                    label: 'Live Tracking',
                    onTap: () => _openRoute(context, AppRoutes.liveTracking),
                  ),
                ],
              ),
            ),
            const Divider(height: 24),
            _SidebarItem(
              icon: Icons.logout_rounded,
              label: 'Logout',
              onTap: onLogout,
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        selected: selected,
        selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: selected ? theme.colorScheme.primary : null),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.bold : FontWeight.w600,
            color: selected ? theme.colorScheme.primary : null,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _AdminDashboardContent extends StatelessWidget {
  const _AdminDashboardContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Welcome, Admin', style: theme.textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          'Manage MyFuel operations from one place.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: MediaQuery.of(context).size.width >= 960 ? 4 : 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.95,
          children: [
            _AdminActionCard(
              title: 'Add Vehicle',
              subtitle: 'Register fleet vehicles',
              icon: Icons.add_road_outlined,
              color: const Color(0xFFD32F2F),
              onTap: () {
                Navigator.of(context).pushNamed(AppRoutes.addVehicle);
              },
            ),
            _AdminActionCard(
              title: 'Manage Vehicle',
              subtitle: 'View assignments',
              icon: Icons.assignment_ind_outlined,
              color: const Color(0xFF1976D2),
              onTap: () {
                Navigator.of(context).pushNamed(AppRoutes.manageVehicles);
              },
            ),
            _AdminActionCard(
              title: 'Fuel Claims',
              subtitle: 'Track fuel spending',
              icon: Icons.payments_outlined,
              color: Color(0xFFFFA000),
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRoutes.fuelClaims),
            ),
            _AdminActionCard(
              title: 'Live Tracking',
              subtitle: 'Monitor driver trips',
              icon: Icons.location_on_outlined,
              color: Color(0xFF2E7D32),
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRoutes.liveTracking),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quick Status', style: theme.textTheme.titleMedium),
                const SizedBox(height: 16),
                const _StatusRow(
                  label: 'System Role',
                  value: 'Admin',
                  icon: Icons.admin_panel_settings_outlined,
                ),
                const Divider(height: 24),
                const _StatusRow(
                  label: 'Access',
                  value: 'Local admin account',
                  icon: Icons.lock_outline_rounded,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AdminActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _AdminActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap:
            onTap ??
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$title admin feature coming soon.')),
              );
            },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                foregroundColor: color,
                child: Icon(icon),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatusRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
