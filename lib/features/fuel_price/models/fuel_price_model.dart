/// Data model representing a Malaysia government fuel price entry.

class FuelPriceModel {
  final String date;
  final double ron95;
  final double ron97;
  final double diesel;
  final String seriesType;

  FuelPriceModel({
    required this.date,
    required this.ron95,
    required this.ron97,
    required this.diesel,
    required this.seriesType
  });

  /// 把JSON数据转换成FuelPriceModel object
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