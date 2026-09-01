import 'package:flutter/material.dart';
import '../../fuel_price/controllers/fuel_price_controller.dart';
import '../../petrol_station/screens/map_page.dart';
import '../../../routes/app_routes.dart';
import '../../fuel_price/widgets/fuel_trend_preview.dart';
import '../../fuel_tracking/pages/fuel_tracking_page.dart';
import '../widgets/driver_shell.dart';

class HomePage extends StatefulWidget {
  final int initialIndex;

  const HomePage({super.key, this.initialIndex = 0});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final int _currentIndex;

  final FuelPriceController _fuelController = FuelPriceController();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _loadFuelPrice();
  }

  Future<void> _loadFuelPrice() async {
    await _fuelController.loadFuelPrice();
    setState(() {});
  }

  String get _pageTitle {
    switch (_currentIndex) {
      case 1:
        return 'Petrol Map';
      case 2:
        return 'Trip Log';
      default:
        return 'MyFuel';
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedRoute = switch (_currentIndex) {
      1 => AppRoutes.driverPetrolMap,
      2 => AppRoutes.driverTripLog,
      _ => AppRoutes.home,
    };

    return DriverShell(
      title: _pageTitle,
      selectedRoute: selectedRoute,
      actions: [
        IconButton(
          icon: const Icon(Icons.bug_report),
          tooltip: 'Developer Test',
          onPressed: () => Navigator.of(context).pushNamed(AppRoutes.osmTest),
        ),
      ],
      child: IndexedStack(
        index: _currentIndex,
        children: [
          _HomeDashboard(fuelController: _fuelController),
          const MapPage(),
          const FuelTrackingPage(),
        ],
      ),
    );
  }
}

class _HomeDashboard extends StatelessWidget {
  final FuelPriceController fuelController;

  const _HomeDashboard({required this.fuelController});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compactHeight = MediaQuery.sizeOf(context).height < 600;
          final horizontalPadding = constraints.maxWidth < 600 ? 18.0 : 32.0;
          final availableWidth = constraints.maxWidth - horizontalPadding * 2;
          final cardWidth = availableWidth >= 600
              ? (availableWidth - 32) / 3
              : availableWidth >= 440
              ? (availableWidth - 16) / 2
              : availableWidth;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              20,
              horizontalPadding,
              36,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHero(context, compact: compactHeight),
                SizedBox(height: compactHeight ? 20 : 28),
                _sectionHeader(
                  context,
                  'Today’s fuel prices',
                  fuelController.fuelPrice == null
                      ? 'Loading latest rates…'
                      : 'Updated ${fuelController.fuelPrice!.date}',
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: _buildFuelPriceCard(
                        context,
                        title: 'RON 95',
                        price: fuelController.fuelPrice == null
                            ? '--'
                            : 'RM ${fuelController.fuelPrice!.ron95.toStringAsFixed(2)}',
                        color: const Color(0xFFD84735),
                        status: fuelController.fuelPrice == null
                            ? '--'
                            : fuelController.getStatus(
                                fuelController.ron95Difference,
                              ),
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _buildFuelPriceCard(
                        context,
                        title: 'RON 97',
                        price: fuelController.fuelPrice == null
                            ? '--'
                            : 'RM ${fuelController.fuelPrice!.ron97.toStringAsFixed(2)}',
                        color: const Color(0xFFF06B32),
                        status: fuelController.fuelPrice == null
                            ? '--'
                            : fuelController.getStatus(
                                fuelController.ron97Difference,
                              ),
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _buildFuelPriceCard(
                        context,
                        title: 'Diesel',
                        price: fuelController.fuelPrice == null
                            ? '--'
                            : 'RM ${fuelController.fuelPrice!.diesel.toStringAsFixed(2)}',
                        color: const Color(0xFFF3A42B),
                        status: fuelController.fuelPrice == null
                            ? '--'
                            : fuelController.getStatus(
                                fuelController.dieselDifference,
                              ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: compactHeight ? 20 : 30),
                const FuelTrendPreview(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHero(BuildContext context, {required bool compact}) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 18 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8E2F25), Color(0xFFD84735), Color(0xFFF07932)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD84735).withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'LIVE IN MALAYSIA',
                    style: TextStyle(
                      color: Color(0xFF7EEDA8),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                SizedBox(height: compact ? 10 : 16),
                Text(
                  compact
                      ? 'Fuel smarter. Drive further.'
                      : 'Fuel smarter.\nDrive further.',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    height: 1.08,
                    letterSpacing: -1,
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Live prices, nearby stations and every trip in one place.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFFFFE0D4),
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 18),
          Container(
            width: compact ? 58 : 72,
            height: compact ? 58 : 72,
            decoration: BoxDecoration(
              color: const Color(0xFFFFC15A),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.local_gas_station_rounded,
              color: Color(0xFF6E251E),
              size: 34,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title, String caption) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
        Text(caption, style: theme.textTheme.bodySmall),
      ],
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
    return Card(
      margin: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white,
          border: Border.all(color: const Color(0xFFF0E2DC)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.local_gas_station_rounded, color: color),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
