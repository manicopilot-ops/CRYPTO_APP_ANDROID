class MarketInfo {
  final String id;
  final String name;
  final String symbol;
  final double currentPrice;
  final double? priceChange24h;
  final List<double> sparkline;
  final double? marketCap;
  final double? volume24h;
  final double? circulatingSupply;
  final double? totalSupply;
  final double? maxSupply;
  final double? low24h;
  final double? high24h;

  MarketInfo({
    required this.id,
    required this.name,
    required this.symbol,
    required this.currentPrice,
    this.priceChange24h,
    this.sparkline = const [],
    this.marketCap,
    this.volume24h,
    this.circulatingSupply,
    this.totalSupply,
    this.maxSupply,
    this.low24h,
    this.high24h,
  });
}
