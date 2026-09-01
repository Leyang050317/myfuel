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
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        toolbarHeight: 68,
        titleSpacing: 20,
        title: Text(title),
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
            if (showSidebar)
              const VerticalDivider(width: 1, color: Color(0xFFF0E2DC)),
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
      color: const Color(0xFF3A1B17),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          compact ? 10 : 16,
          showTopSpacer ? kToolbarHeight + 58 : 22,
          compact ? 10 : 16,
          16,
        ),
        child: Column(
          children: [
            if (!showTopSpacer) ...[
              Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 8 : 12,
                  4,
                  compact ? 8 : 12,
                  24,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFA343),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.local_gas_station_rounded,
                        color: Color(0xFF3A1B17),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'MyFuel Admin',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
            const Divider(height: 24, color: Color(0xFF60372F)),
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
    final color = selected ? const Color(0xFF3A1B17) : const Color(0xFFE0C9C2);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: compact,
        contentPadding: EdgeInsets.symmetric(horizontal: compact ? 10 : 16),
        minLeadingWidth: compact ? 20 : null,
        horizontalTitleGap: compact ? 8 : 16,
        selected: selected,
        selectedTileColor: const Color(0xFFFFA343),
        hoverColor: Colors.white.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Icon(icon, color: color, size: compact ? 20 : 24),
        title: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: compact ? 13 : null,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: color,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
