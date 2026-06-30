/// Controller managing fuel price data loading and state.

import '../models/fuel_price_model.dart';
import '../services/fuel_price_service.dart';

class FuelPriceController {
  final FuelPriceService _service = FuelPriceService();

  FuelPriceModel? fuelPrice;

  double ron95Difference = 0;
  double ron97Difference = 0;
  double dieselDifference = 0;

  Future<void> loadFuelPrice() async {
    final prices = await _service.getLatestFuelPrices();
    /// prices[0] = level
    /// prices[1] = differenc price between week

    fuelPrice = prices[0];

    ron95Difference = prices[1].ron95;
    ron97Difference = prices[1].ron97;
    dieselDifference = prices[1].diesel;
  }

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