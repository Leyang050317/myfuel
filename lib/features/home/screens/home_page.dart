import 'package:flutter/material.dart';
import '../../fuel_price/controllers/fuel_price_controller.dart';
import '../../petrol_station/screens/map_page.dart';
import '../../petrol_station/screens/search_page.dart';
import '../../../routes/app_routes.dart';

/// Main home screen container housing the bottom navigation bar and tabs.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final FuelPriceController _fuelController = FuelPriceController();

  // The list of screens to show per tab


  @override
  void initState() {
    super.initState();

    _loadFuelPrice();
  }

  Future<void> _loadFuelPrice() async {
    await _fuelController.loadFuelPrice();

    print(_fuelController.fuelPrice?.ron95);
    print(_fuelController.fuelPrice?.ron97);
    print(_fuelController.fuelPrice?.diesel);

    setState(() {});
  }

  /// Changes the current page index
  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // Keep the appBar visible only when we are on the home dashboard page
      appBar: _currentIndex == 0
          ? AppBar(
              title: const Text(
                'MyFuel Dashboard',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              backgroundColor: Colors.white,
              foregroundColor: theme.colorScheme.onBackground,
              elevation: 0,
              centerTitle: false,
              actions: [
                IconButton(
                  onPressed: () {
                    // Sign out redirect
                    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
                  },
                  icon: const Icon(Icons.logout_rounded),
                  tooltip: 'Logout',
                ),
                const SizedBox(width: 8),
              ],
            )
          : null,

      body: IndexedStack(
        index: _currentIndex,
        children: [
          _HomeDashboard(
            fuelController: _fuelController,
            onMapTap: () => _navigateToTab(1),
            onSearchTap: () => _navigateToTab(2),
          ),
          const MapPage(),
          const SearchPage(),
        ],
      ),

      // Material Design 3 Navigation Bar
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _navigateToTab,
        indicatorColor: theme.colorScheme.primary.withOpacity(0.12),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: Colors.red),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map_rounded, color: Colors.red),
            label: 'Petrol Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_gas_station_outlined),
            selectedIcon: Icon(Icons.local_gas_station_rounded, color: Colors.red),
            label: 'Find Stations',
          ),
        ],
      ),
    );
  }
}

/// Dedicated widget for rendering the Home Dashboard tab to prevent initState context lookups.
class _HomeDashboard extends StatelessWidget {
  final FuelPriceController fuelController;

  final VoidCallback onMapTap;
  final VoidCallback onSearchTap;

  const _HomeDashboard({
    required this.fuelController,
    required this.onMapTap,
    required this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Text(
              'Welcome to MyFuel!',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Real-time fuel rates in Malaysia',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            // Fuel rates title
            Text(
              'Fuel Prices',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            
            // RON 95 (Primary Color Theme)
            _buildFuelPriceCard(
              context,
              title: 'RON 95',
              price: fuelController.fuelPrice == null
                  ? "Loading..."
                  : "RM ${fuelController.fuelPrice!.ron95.toStringAsFixed(2)}",
              color: theme.colorScheme.primary,
              status: fuelController.getStatus(
                fuelController.ron95Difference,
              ),
            ),
            const SizedBox(height: 12),

            // RON 97 (Secondary Color Theme)
            _buildFuelPriceCard(
              context,
              title: 'RON 97',
              price: fuelController.fuelPrice == null
                  ? "Loading..."
                  : "RM ${fuelController.fuelPrice!.ron97.toStringAsFixed(2)}",
              color: theme.colorScheme.secondary,
              status: fuelController.getStatus(
                fuelController.ron97Difference,
              ),
            ),
            const SizedBox(height: 12),

            // Diesel (Accent Color Theme)
            _buildFuelPriceCard(
              context,
              title: 'Diesel B10',
              price: fuelController.fuelPrice == null
                  ? "Loading..."
                  : "RM ${fuelController.fuelPrice!.diesel.toStringAsFixed(2)}",
              color: theme.colorScheme.tertiary,
              status: fuelController.getStatus(
                fuelController.dieselDifference,
              ),
            ),
            const SizedBox(height: 32),

            // Quick Navigator Actions
            Text(
              'Quick Navigator',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    context,
                    icon: Icons.map_outlined,
                    label: 'Petrol Map',
                    onTap: onMapTap,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionCard(
                    context,
                    icon: Icons.local_gas_station_outlined,
                    label: 'Find Stations',
                    onTap: onSearchTap,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFuelPriceCard(
    BuildContext context, {
    required String title,
    required String price,
    required Color color,
    required String status,
  }) {
    final theme = Theme.of(context);
    final isAmber = color == theme.colorScheme.tertiary;

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: color.withOpacity(0.08),
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isAmber ? Colors.amber.shade900 : color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onBackground.withOpacity(0.55),
                  ),
                ),
              ],
            ),
            Text(
              price,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 36,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
