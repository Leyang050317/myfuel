/// Widget rendering a chart of historical fuel price trends.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/fuel_price_model.dart';

/// Fuel Trend 折线图
class FuelTrendChart extends StatelessWidget {

  final List<FuelPriceModel> history;
  final String fuelType;

  const FuelTrendChart({
    super.key,
    required this.history,
    required this.fuelType,
  });

  @override
  Widget build(BuildContext context) {
    List<FlSpot> spots = [];

    final reversedHistory = history.reversed.toList();
    for (int i = 0; i < history.length; i++) {
      double value;

      switch (fuelType) {
        case "RON97":
          value = reversedHistory[i].ron97;
          break;

        case "Diesel":
          value = reversedHistory[i].diesel;
          break;

        default:
          value = reversedHistory[i].ron95;
      }

      spots.add(
        FlSpot(
          i.toDouble(),
          value,
        ),
      );
    }

    return SizedBox(
      height: 250,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true),
          borderData: FlBorderData(show: true),

          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();

                  if (index >= reversedHistory.length) {
                    return const SizedBox();
                  }

                  final date = reversedHistory[index].date;

                  // 2026-06-25 -> 25/06
                  final parts = date.split("-");

                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      "${parts[2]}/${parts[1]}",
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),

          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              dotData: const FlDotData(show: true),

              spots: spots,
            ),
          ],
        ),
      ),
    );
  }
}