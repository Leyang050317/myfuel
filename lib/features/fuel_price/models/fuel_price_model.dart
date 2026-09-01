library;

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
    required this.seriesType,
  });

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
