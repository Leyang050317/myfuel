/// Controller managing fuel price data loading and state.

import '../models/fuel_price_model.dart';
import '../services/fuel_price_service.dart';

class FuelPriceController {
  // 建立 FuelPriceService，用于向 Government Open Data API 取得油价资料
  final FuelPriceService _service = FuelPriceService();

  // 储存最新一期油价资料
  FuelPriceModel? fuelPrice;

  // 储存本周油价变化值
  double ron95Difference = 0;
  double ron97Difference = 0;
  double dieselDifference = 0;

  /// 从 API 读取最新油价及本周变化数据
  Future<void> loadFuelPrice() async {

    // 取得最新两笔资料
    final prices = await _service.getLatestFuelPrices();

    // prices[0]：最新油价（series_type = level）
    // prices[1]：本周油价变化（series_type = change_weekly）

    // 保存最新油价
    fuelPrice = prices[0];

    // 保存本周变化值
    ron95Difference = prices[1].ron95;
    ron97Difference = prices[1].ron97;
    dieselDifference = prices[1].diesel;
  }

  /// 根据变化值回传对应的状态文字
  String getStatus(double difference) {
    if (difference > 0) {
      return "▲ RM ${difference.toStringAsFixed(2)} this week";
    } else if (difference < 0) {
      return "▼ RM ${difference.abs().toStringAsFixed(2)} this week";
    } else {
      return "No change this week";
    }
  }
}