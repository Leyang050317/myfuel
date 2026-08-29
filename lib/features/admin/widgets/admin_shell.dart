import 'package:flutter/material.dart';

import '../../../routes/app_routes.dart';

class AdminShell extends StatelessWidget {
  final String title;
  final String selectedRoute;
  final Widget child;
  final List<Widget>? actions;

  const AdminShell({
    super.key,
    required this.title,
    required this.selectedRoute,
    required this.child,
    this.actions,
  });

  void _logout(BuildContext context) {
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final showSidebar = mediaQuery.size.width >= 720;
    final compactSidebar =
        mediaQuery.orientation == Orientation.landscape &&
        mediaQuery.size.width < 1100;
    final isDashboard = selectedRoute == AppRoutes.admin;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: theme.colorScheme.onSurface,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: isDashboard
            ? showSidebar
                  ? null
                  : Builder(
                      builder: (context) => IconButton(
                        tooltip: 'Menu',
                        onPressed: () => Scaffold.of(context).openDrawer(),
                        icon: const Icon(Icons.menu_rounded),
                      ),
                    )
            : IconButton(
                tooltip: 'Back to dashboard',
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed(AppRoutes.admin);
                },
                icon: const Icon(Icons.arrow_back_rounded),
              ),
        actions: [...?actions, const SizedBox(width: 8)],
      ),
      drawer: showSidebar
          ? null
          : Drawer(
              child: _AdminSidebar(
                selectedRoute: selectedRoute,
                onLogout: () => _logout(context),
                showTopSpacer: true,
                compact: false,
              ),
            ),
      body: SafeArea(
        child: Row(
          children: [
            if (showSidebar)
              SizedBox(
                width: compactSidebar ? 220 : 264,
                child: _AdminSidebar(
                  selectedRoute: selectedRoute,
                  onLogout: () => _logout(context),
                  compact: compactSidebar,
                ),
              ),
            if (showSidebar) const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _AdminSidebar extends StatelessWidget {
  final String selectedRoute;
  final VoidCallback onLogout;
  final bool showTopSpacer;
  final bool compact;

  const _AdminSidebar({
    required this.selectedRoute,
    required this.onLogout,
    this.showTopSpacer = false,
    this.compact = false,
  });

  void _openRoute(BuildContext context, String routeName) {
    final navigator = Navigator.of(context);
    if (Scaffold.maybeOf(context)?.isDrawerOpen == true) {
      navigator.pop();
    }
    if (selectedRoute == routeName) return;
    navigator.pushReplacementNamed(routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          compact ? 10 : 16,
          showTopSpacer ? kToolbarHeight + 58 : 22,
          compact ? 10 : 16,
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
                    selected: selectedRoute == AppRoutes.admin,
                    compact: compact,
                    onTap: () => _openRoute(context, AppRoutes.admin),
                  ),
                  _SidebarItem(
                    icon: Icons.add_road_outlined,
                    label: 'Add Vehicle',
                    selected: selectedRoute == AppRoutes.addVehicle,
                    compact: compact,
                    onTap: () => _openRoute(context, AppRoutes.addVehicle),
                  ),
                  _SidebarItem(
                    icon: Icons.assignment_ind_outlined,
                    label: 'Manage Vehicle',
                    selected: selectedRoute == AppRoutes.manageVehicles,
                    compact: compact,
                    onTap: () => _openRoute(context, AppRoutes.manageVehicles),
                  ),
                  _SidebarItem(
                    icon: Icons.payments_outlined,
                    label: 'Fuel Claims',
                    selected: selectedRoute == AppRoutes.fuelClaims,
                    compact: compact,
                    onTap: () => _openRoute(context, AppRoutes.fuelClaims),
                  ),
                  _SidebarItem(
                    icon: Icons.insights_outlined,
                    label: 'Fuel Monitoring',
                    selected: selectedRoute == AppRoutes.fuelMonitoring,
                    compact: compact,
                    onTap: () => _openRoute(context, AppRoutes.fuelMonitoring),
                  ),
                  _SidebarItem(
                    icon: Icons.location_on_outlined,
                    label: 'Live Tracking',
                    selected: selectedRoute == AppRoutes.liveTracking,
                    compact: compact,
                    onTap: () => _openRoute(context, AppRoutes.liveTracking),
                  ),
                ],
              ),
            ),
            const Divider(height: 24),
            _SidebarItem(
              icon: Icons.logout_rounded,
              label: 'Logout',
              compact: compact,
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
  final bool compact;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : const Color(0xFF42474D);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: compact,
        contentPadding: EdgeInsets.symmetric(horizontal: compact ? 10 : 16),
        minLeadingWidth: compact ? 20 : null,
        horizontalTitleGap: compact ? 8 : 16,
        selected: selected,
        selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: Icon(icon, color: color, size: compact ? 20 : 24),
        title: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: compact ? 13 : null,
            fontWeight: selected ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
