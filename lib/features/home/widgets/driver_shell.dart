import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../routes/app_routes.dart';

class DriverShell extends StatelessWidget {
  final String title;
  final String selectedRoute;
  final Widget child;
  final List<Widget>? actions;

  const DriverShell({
    super.key,
    required this.title,
    required this.selectedRoute,
    required this.child,
    this.actions,
  });

  Future<void> _logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final showSidebar = mediaQuery.size.width >= 720;
    final compact =
        mediaQuery.orientation == Orientation.landscape &&
        mediaQuery.size.width < 1100;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        toolbarHeight: 68,
        titleSpacing: 20,
        title: Text(title),
        leading: showSidebar
            ? null
            : Builder(
                builder: (context) => IconButton(
                  tooltip: 'Menu',
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  icon: const Icon(Icons.menu_rounded),
                ),
              ),
        actions: [...?actions, const SizedBox(width: 8)],
      ),
      drawer: showSidebar
          ? null
          : Drawer(
              child: _DriverSidebar(
                selectedRoute: selectedRoute,
                onLogout: () => _logout(context),
                showTopSpacer: true,
              ),
            ),
      body: SafeArea(
        child: Row(
          children: [
            if (showSidebar)
              SizedBox(
                width: compact ? 220 : 264,
                child: _DriverSidebar(
                  selectedRoute: selectedRoute,
                  onLogout: () => _logout(context),
                  compact: compact,
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

class _DriverSidebar extends StatelessWidget {
  final String selectedRoute;
  final VoidCallback onLogout;
  final bool showTopSpacer;
  final bool compact;

  const _DriverSidebar({
    required this.selectedRoute,
    required this.onLogout,
    this.showTopSpacer = false,
    this.compact = false,
  });

  void _openRoute(BuildContext context, String route) {
    final navigator = Navigator.of(context);
    if (Scaffold.maybeOf(context)?.isDrawerOpen == true) navigator.pop();
    if (selectedRoute != route) navigator.pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF3A1B17),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          compact ? 10 : 16,
          showTopSpacer ? kToolbarHeight + 50 : 18,
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
                        'MyFuel',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
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
                  _item(context, Icons.home_outlined, 'Home', AppRoutes.home),
                  _item(
                    context,
                    Icons.map_outlined,
                    'Petrol Map',
                    AppRoutes.driverPetrolMap,
                  ),
                  _item(
                    context,
                    Icons.route_outlined,
                    'Trip Log',
                    AppRoutes.driverTripLog,
                  ),
                  _item(
                    context,
                    Icons.payments_outlined,
                    'Fuel Claim',
                    AppRoutes.fuelCalculator,
                  ),
                  _item(
                    context,
                    Icons.history_outlined,
                    'Fuel History',
                    AppRoutes.fuelHistory,
                  ),
                  _item(
                    context,
                    Icons.local_gas_station_outlined,
                    'Add Refuel',
                    AppRoutes.refuelRecord,
                  ),
                  _item(
                    context,
                    Icons.insights_outlined,
                    'Fuel Dashboard',
                    AppRoutes.fuelDashboard,
                  ),
                  _DriverSidebarItem(
                    icon: Icons.bug_report_outlined,
                    label: 'Developer Test',
                    compact: compact,
                    onTap: () {
                      final navigator = Navigator.of(context);
                      if (Scaffold.maybeOf(context)?.isDrawerOpen == true) {
                        navigator.pop();
                      }
                      navigator.pushNamed(AppRoutes.osmTest);
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 24, color: Color(0xFF60372F)),
            _DriverSidebarItem(
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

  Widget _item(
    BuildContext context,
    IconData icon,
    String label,
    String route,
  ) {
    return _DriverSidebarItem(
      icon: icon,
      label: label,
      selected: selectedRoute == route,
      compact: compact,
      onTap: () => _openRoute(context, route),
    );
  }
}

class _DriverSidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final bool compact;

  const _DriverSidebarItem({
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
