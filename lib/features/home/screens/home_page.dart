import 'package:flutter/material.dart';
import '../../fuel_price/controllers/fuel_price_controller.dart';
import '../../petrol_station/screens/map_page.dart';
import '../../../routes/app_routes.dart';
import '../../fuel_price/widgets/fuel_trend_preview.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../map/screens/osm_test_page.dart';
import '../../fuel_tracking/pages/fuel_tracking_page.dart';

/// Main home screen container
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final FuelPriceController _fuelController = FuelPriceController();

  /// 初始化页面，并读取最新油价资料
  @override
  void initState() {
    super.initState();

    _loadFuelPrice();
  }

  /// 从 Controller 读取最新油价，并更新画面
  Future<void> _loadFuelPrice() async {
    await _fuelController.loadFuelPrice();
    setState(() {});
  }

  /// 切换侧边导航页面
  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
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

  /// 建立首页画面
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showSidebar = MediaQuery.of(context).size.width >= 720;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _pageTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
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
            icon: const Icon(Icons.bug_report),
            tooltip: 'Developer Test',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OSMTestPage()),
              );
            },
          ),

          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: showSidebar
          ? null
          : Drawer(
              child: _DriverSidebar(
                currentIndex: _currentIndex,
                onSelect: (index) {
                  Navigator.of(context).pop();
                  _navigateToTab(index);
                },
                onDeveloperTest: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OSMTestPage()),
                  );
                },
                onLogout: () {
                  Navigator.of(context).pop();
                  _logout();
                },
                showTopSpacer: true,
              ),
            ),
      body: SafeArea(
        child: Row(
          children: [
            if (showSidebar)
              SizedBox(
                width: 260,
                child: _DriverSidebar(
                  currentIndex: _currentIndex,
                  onSelect: _navigateToTab,
                  onDeveloperTest: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OSMTestPage()),
                    );
                  },
                  onLogout: _logout,
                ),
              ),
            if (showSidebar) const VerticalDivider(width: 1),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  _HomeDashboard(fuelController: _fuelController),
                  const MapPage(),
                  const FuelTrackingPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DriverSidebar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onDeveloperTest;
  final VoidCallback onLogout;
  final bool showTopSpacer;

  const _DriverSidebar({
    required this.currentIndex,
    required this.onSelect,
    required this.onDeveloperTest,
    required this.onLogout,
    this.showTopSpacer = false,
  });

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
                  _DriverSidebarItem(
                    icon: Icons.home_outlined,
                    label: 'Home',
                    selected: currentIndex == 0,
                    onTap: () => onSelect(0),
                  ),
                  _DriverSidebarItem(
                    icon: Icons.map_outlined,
                    label: 'Petrol Map',
                    selected: currentIndex == 1,
                    onTap: () => onSelect(1),
                  ),
                  _DriverSidebarItem(
                    icon: Icons.route_outlined,
                    label: 'Trip Log',
                    selected: currentIndex == 2,
                    onTap: () => onSelect(2),
                  ),
                  _DriverSidebarItem(
                    icon: Icons.payments_outlined,
                    label: 'Fuel Claim',
                    onTap: () => Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.fuelCalculator),
                  ),
                  _DriverSidebarItem(
                    icon: Icons.history_outlined,
                    label: 'Fuel History',
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.fuelHistory),
                  ),
                  _DriverSidebarItem(
                    icon: Icons.local_gas_station_outlined,
                    label: 'Add Refuel',
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.refuelRecord),
                  ),
                  _DriverSidebarItem(
                    icon: Icons.insights_outlined,
                    label: 'Fuel Dashboard',
                    onTap: () => Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.fuelDashboard),
                  ),
                  _DriverSidebarItem(
                    icon: Icons.bug_report_outlined,
                    label: 'Developer Test',
                    onTap: onDeveloperTest,
                  ),
                ],
              ),
            ),
            const Divider(height: 24),
            _DriverSidebarItem(
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

class _DriverSidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  const _DriverSidebarItem({
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

/// 首页仪表板，负责显示油价资讯
class _HomeDashboard extends StatelessWidget {
  final FuelPriceController fuelController;

  const _HomeDashboard({required this.fuelController});

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
            // 欢迎讯息
            Text('Welcome to MyFuel!', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Real-time fuel rates in Malaysia',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            // 油价资讯标题
            Text('Fuel Prices', style: theme.textTheme.titleMedium),

            const SizedBox(height: 12),

            // 显示最新油价更新时间
            Text(
              fuelController.fuelPrice == null
                  ? "Loading..."
                  : "Last Updated: ${fuelController.fuelPrice!.date}",
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 12),

            // RON95 油价资讯卡
            _buildFuelPriceCard(
              context,
              title: 'RON 95',
              price: fuelController.fuelPrice == null
                  ? "--"
                  : "RM ${fuelController.fuelPrice!.ron95.toStringAsFixed(2)}",
              color: theme.colorScheme.primary,
              status: fuelController.fuelPrice == null
                  ? "--"
                  : fuelController.getStatus(fuelController.ron95Difference),
            ),
            const SizedBox(height: 12),

            // RON97 油价资讯卡
            _buildFuelPriceCard(
              context,
              title: 'RON 97',
              price: fuelController.fuelPrice == null
                  ? "--"
                  : "RM ${fuelController.fuelPrice!.ron97.toStringAsFixed(2)}",
              color: theme.colorScheme.secondary,
              status: fuelController.fuelPrice == null
                  ? "--"
                  : fuelController.getStatus(fuelController.ron97Difference),
            ),

            const SizedBox(height: 12),

            // Diesel 油价资讯卡
            _buildFuelPriceCard(
              context,
              title: 'Diesel',
              price: fuelController.fuelPrice == null
                  ? "--"
                  : "RM ${fuelController.fuelPrice!.diesel.toStringAsFixed(2)}",
              color: theme.colorScheme.tertiary,
              status: fuelController.fuelPrice == null
                  ? "--"
                  : fuelController.getStatus(fuelController.dieselDifference),
            ),

            const SizedBox(height: 28),

            const FuelTrendPreview(),
          ],
        ),
      ),
    );
  }

  /// 建立单张油价资讯卡片
  Widget _buildFuelPriceCard(
    BuildContext context, {
    required String title, // 油品名称
    required String price, // 目前油价
    required Color color, // 卡片主题颜色
    required String status, // 本周价格变化
  }) {
    final theme = Theme.of(context);
    final isAmber = color == theme.colorScheme.tertiary;

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

      // 油价卡片内容
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: color.withValues(alpha: 0.08),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 左侧显示油品名称及本周价格变化
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
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),

            // 右侧显示目前油价
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
}
