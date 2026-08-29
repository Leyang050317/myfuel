import 'package:flutter/material.dart';
import '../widgets/fuel_trend_chart.dart';
import '../controllers/fuel_trend_controller.dart';

/// Fuel Trend 页面，显示历史油价走势图
class FuelTrendPage extends StatefulWidget {
  const FuelTrendPage({super.key});

  @override
  State<FuelTrendPage> createState() => _FuelTrendPageState();
}

class _FuelTrendPageState extends State<FuelTrendPage> {
  final FuelTrendController _controller = FuelTrendController();

  @override
  void initState() {
    super.initState();

    _loadHistory();
  }

  Future<void> _loadHistory() async {
    await _controller.loadHistory();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Fuel Price Trend"), centerTitle: true),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Historical Fuel Prices", style: theme.textTheme.titleLarge),

              const SizedBox(height: 6),

              Text(
                "View Malaysia fuel price trends over the past weeks.",
                style: theme.textTheme.bodyMedium,
              ),

              const SizedBox(height: 24),

              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: FuelTrendChart(history: _controller.history),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
