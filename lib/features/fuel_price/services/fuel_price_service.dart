/// Service for fetching current and historical fuel price data.

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/fuel_price_model.dart';

class FuelPriceService {

  /// 获取最新两周油价
  Future<List<FuelPriceModel>> getLatestFuelPrices() async {

    /// sort=-date 日期从最新排到最救
    /// limit=2 拿最新的两笔资料
    final url = Uri.parse(
      "https://api.data.gov.my/data-catalogue?id=fuelprice&sort=-date&limit=2",
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception("Failed to load fuel price");
    }

    final List<dynamic> json = jsonDecode(response.body);

    return json
        .map((item) => FuelPriceModel.fromJson(item))
        .toList();
  }
}