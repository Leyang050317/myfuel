/// Service for fetching current and historical fuel price data.

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/fuel_price_model.dart';

/// 负责向 Government Open Data API 获取油价资料。
class FuelPriceService {

  /// 获取最新两笔油价资料：
  /// 第一笔为最新油价（level），
  /// 第二笔为本周油价变化（change_weekly）
  Future<List<FuelPriceModel>> getLatestFuelPrices() async {

    /// sort=-date：依日期由新到旧排序
    /// limit=2：只取得最新两笔资料
    final url = Uri.parse(
      "https://api.data.gov.my/data-catalogue?id=fuelprice&sort=-date&limit=2",
    );

    // 向 Government Open Data API 发送 GET 请求
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception("Failed to load fuel price");
    }

    // 将 API 回传的 JSON 字串转换成 List<dynamic>
    final List<dynamic> json = jsonDecode(response.body);

    // 将每一笔 JSON 资料转换成 FuelPriceModel 对象
    return json
        .map((item) => FuelPriceModel.fromJson(item))
        .toList();
  }
}