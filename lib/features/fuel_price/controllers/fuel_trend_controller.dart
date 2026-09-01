import '../models/fuel_price_model.dart';
import '../services/fuel_price_service.dart';

class FuelTrendController {
  final FuelPriceService _service = FuelPriceService();

  List<FuelPriceModel> history = [];

  Future<void> loadHistory() async {
    final allHistory = await _service.getFuelHistory();

    history = allHistory.take(6).toList();
  }
}
