import 'package:flutter/material.dart';
import '../controllers/fuel_trend_controller.dart';
import 'fuel_trend_chart.dart';

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
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Navigator.pushNamed(context, '/fuel-trend');
        },
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFF0E2DC)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Fuel Price Trend", style: theme.textTheme.titleMedium),

                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 19,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7F2),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: _controller.history.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : Padding(
                        padding: const EdgeInsets.all(8),
                        child: FuelTrendChart(
                          history: _controller.history,
                          height: 134,
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
