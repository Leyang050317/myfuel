library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/fuel_price_model.dart';

class FuelPriceService {
  Future<double> getCurrentPriceForFuelType(String fuelType) async {
    final prices = await getLatestFuelPrices();
    FuelPriceModel? latest;
    for (final price in prices) {
      if (price.seriesType == 'level') {
        latest = price;
        break;
      }
    }
    if (latest == null) throw StateError('No current fuel price is available.');
    switch (fuelType) {
      case 'RON95':
        return latest.ron95;
      case 'RON97':
        return latest.ron97;
      case 'Diesel':
        return latest.diesel;
      default:
        throw UnsupportedError(
          '$fuelType is not supported by the petroleum price API.',
        );
    }
  }

  Future<List<FuelPriceModel>> getLatestFuelPrices() async {

    final url = Uri.parse(
      "https://api.data.gov.my/data-catalogue?id=fuelprice&sort=-date&limit=2",
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception("Failed to load fuel price");
    }

    final List<dynamic> json = jsonDecode(response.body);

    return json.map((item) => FuelPriceModel.fromJson(item)).toList();
  }

  Future<List<FuelPriceModel>> getFuelHistory() async {
    final url = Uri.parse(
      "https://api.data.gov.my/data-catalogue?id=fuelprice&sort=-date&limit=24",
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception("Failed to load fuel history");
    }

    final List<dynamic> json = jsonDecode(response.body);

    final prices = json.map((item) => FuelPriceModel.fromJson(item)).toList();

    return prices.where((item) => item.seriesType == "level").toList();
  }
}
