library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/fuel_price_model.dart';

class FuelTrendChart extends StatelessWidget {
  final List<FuelPriceModel> history;
  final double height;

  const FuelTrendChart({super.key, required this.history, this.height = 250});

  static const _ron95Color = Color(0xFFD32F2F);
  static const _ron97Color = Color(0xFF1976D2);
  static const _dieselColor = Color(0xFFFFA000);

  @override
  Widget build(BuildContext context) {
    final reversedHistory = history.reversed.toList();
    final ron95Spots = _spots(reversedHistory, (item) => item.ron95);
    final ron97Spots = _spots(reversedHistory, (item) => item.ron97);
    final dieselSpots = _spots(reversedHistory, (item) => item.diesel);

    return SizedBox(
      height: height,
      child: Column(
        children: [
          const Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _LegendItem(label: 'RON95', color: _ron95Color),
              _LegendItem(label: 'RON97', color: _ron97Color),
              _LegendItem(label: 'Diesel', color: _dieselColor),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBorderRadius: BorderRadius.circular(10),
                    getTooltipColor: (_) => Colors.black87,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final item = reversedHistory[spot.x.toInt()];
                        final fuelNames = ['RON95', 'RON97', 'Diesel'];
                        final colors = [_ron95Color, _ron97Color, _dieselColor];
                        final parts = item.date.split('-');
                        final date = parts.length == 3
                            ? '${parts[2]}/${parts[1]}'
                            : item.date;
                        final showDate = spot.barIndex == 0 ? '$date\n' : '';

                        return LineTooltipItem(
                          '$showDate${fuelNames[spot.barIndex]}: '
                          'RM ${spot.y.toStringAsFixed(2)}',
                          TextStyle(
                            color: colors[spot.barIndex],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 0.10,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: Colors.grey.shade300, strokeWidth: 1),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    left: BorderSide(color: Colors.grey.shade400),
                    bottom: BorderSide(color: Colors.grey.shade400),
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= reversedHistory.length) {
                          return const SizedBox();
                        }
                        final parts = reversedHistory[index].date.split('-');
                        final label = parts.length == 3
                            ? '${parts[2]}/${parts[1]}'
                            : reversedHistory[index].date;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            label,
                            style: const TextStyle(fontSize: 9),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  _line(ron95Spots, _ron95Color),
                  _line(ron97Spots, _ron97Color),
                  _line(dieselSpots, _dieselColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _spots(
    List<FuelPriceModel> items,
    double Function(FuelPriceModel item) valueOf,
  ) {
    return List.generate(
      items.length,
      (index) => FlSpot(index.toDouble(), valueOf(items[index])),
    );
  }

  LineChartBarData _line(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      barWidth: 2.5,
      color: color,
      dotData: const FlDotData(show: true),
      belowBarData: BarAreaData(show: false),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendItem({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
