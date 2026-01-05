class PricePoint {
  final DateTime time;
  final double price;
  final double? volume;
  final double? marketCap;

  PricePoint({
    required this.time,
    required this.price,
    this.volume,
    this.marketCap,
  });
}
