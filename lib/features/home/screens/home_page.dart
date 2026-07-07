import 'package:flutter/material.dart';
import '../../fuel_price/controllers/fuel_price_controller.dart';
import '../../petrol_station/screens/map_page.dart';
import '../../petrol_station/screens/search_page.dart';
import '../../../routes/app_routes.dart';
import '../../fuel_price/widgets/fuel_trend_preview.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  /// 切换底部导航页面
  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  /// 建立首页画面
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // 仅在首页显示 AppBar
      appBar: _currentIndex == 0
          ? AppBar(
              title: const Text(
                'MyFuel',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              backgroundColor: Colors.white,
              foregroundColor: theme.colorScheme.onBackground,
              elevation: 0,
              centerTitle: false,
              actions: [
                IconButton(
                  onPressed: () async{
                    // 登出并返回登入页面
                    await Supabase.instance.client.auth.signOut();
                    if(!context.mounted)return;
                    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
                  },
                  icon: const Icon(Icons.logout_rounded),
                  tooltip: 'Logout',
                ),
                const SizedBox(width: 8),
              ],
            )
          : null,

      // 使用 IndexedStack 保留各页面状态，切换页面时不会重新建立
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _HomeDashboard(
            fuelController: _fuelController,
          ),
          const MapPage(),
          const SearchPage(),
        ],
      ),

      // 底部导航栏
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

/// 首页仪表板，负责显示油价资讯
class _HomeDashboard extends StatelessWidget {
  final FuelPriceController fuelController;

  const _HomeDashboard({
    required this.fuelController,
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
            // 欢迎讯息
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

            // 油价资讯标题
            Text(
              'Fuel Prices',
              style: theme.textTheme.titleMedium,
            ),

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
                  : fuelController.getStatus(
                fuelController.ron95Difference,
              ),
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
                  : fuelController.getStatus(
                fuelController.ron97Difference,
              ),
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
                  : fuelController.getStatus(
                fuelController.dieselDifference,
              ),
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
    required String title,  // 油品名称
    required String price,  // 目前油价
    required Color color,   // 卡片主题颜色
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
          color: color.withOpacity(0.08),
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
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
                    color: theme.colorScheme.onBackground.withOpacity(0.55),
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
