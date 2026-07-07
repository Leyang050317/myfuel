import 'package:flutter/material.dart';
import '../../../routes/app_routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 应用程式启动页面，负责显示品牌 Logo 并进入登录页面
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;   // 控制 Splash Screen 淡入动画
  late Animation<double> _fadeAnimation;  // 淡入动画效果

  /// 初始化动画，并在指定时间后进入登录页面。
  @override
  void initState() {
    super.initState();

    // 建立动画控制器
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // 建立由透明到完全显示的淡入动画
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    // 开始播放动画
    _controller.forward();

    // Splash Screen 停留 2.5 秒后自动进入登录页面
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;

      final session = Supabase.instance.client.auth.currentSession;

      if (session != null) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
      } else {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 建立 Splash Screen 画面
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Splash Screen 页面主体
    return Scaffold(
      backgroundColor: theme.colorScheme.primary, // 使用主题主色作为 Splash Screen 背景
      body: SafeArea(
        child: Center(
          child: FadeTransition(  // 套用淡入动画
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 圆形 Logo 容器
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.local_gas_station_rounded,
                    size: 72,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                // App Title
                const Text(
                  'MyFuel',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                // App Subtitle
                Text(
                  'Malaysia Fuel Price & Petrol Station Navigator',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.85),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
