/// Data model representing a Malaysia government fuel price entry.

class FuelPriceModel {
  final String date;
  final double ron95;
  final double ron97;
  final double diesel;
  final String seriesType; // 资料类型（level、change_weekly）

  FuelPriceModel({
    required this.date,
    required this.ron95,
    required this.ron97,
    required this.diesel,
    required this.seriesType
  });

  /// 将 Government Open Data API 回传的 JSON 数据转换成 FuelPriceModel 对象，方便 Flutter 程式读取与使用
  /// Key是String
  /// Value是任何类型，所以用dynamic
  factory FuelPriceModel.fromJson(Map<String, dynamic> json) {
    return FuelPriceModel(
      date: json['date'],
      ron95: (json['ron95'] as num).toDouble(),
      ron97: (json['ron97'] as num).toDouble(),
      diesel: (json['diesel'] as num).toDouble(),
      seriesType: json["series_type"],
    );
  }
}