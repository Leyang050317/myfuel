import 'package:flutter/material.dart';
import '../controllers/fuel_trend_controller.dart';
import 'fuel_trend_chart.dart';

/// Fuel Trend 预览卡片
class FuelTrendPreview extends StatefulWidget {
  const FuelTrendPreview({super.key});

  @override
  State<FuelTrendPreview> createState() => _FuelTrendPreviewState();
}

class _FuelTrendPreviewState extends State<FuelTrendPreview> {
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

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/fuel-trend',
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  Text(
                    "Fuel Price Trend",
                    style: theme.textTheme.titleMedium,
                  ),

                  const Icon(Icons.arrow_forward_ios_rounded, size: 18),

                ],
              ),

              const SizedBox(height: 16),

              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _controller.history.isEmpty
                    ? const Center(
                      child: CircularProgressIndicator(),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(8),
                        child: FuelTrendChart(
                          history: _controller.history,
                          fuelType: "RON95",
                      ),
                    ),
              ),

              const SizedBox(height: 12),

              Text(
                "Tap to view historical fuel prices",
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}