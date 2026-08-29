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
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
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
            if (showSidebar) const VerticalDivider(width: 1),
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
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          compact ? 10 : 16,
          showTopSpacer ? kToolbarHeight + 50 : 18,
          compact ? 10 : 16,
          16,
        ),
        child: Column(
          children: [
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
            const Divider(height: 24),
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
    final theme = Theme.of(context);
    final color = selected ? theme.colorScheme.primary : null;
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
