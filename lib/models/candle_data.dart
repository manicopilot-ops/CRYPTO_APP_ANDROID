class CandleData {
  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;
  final double? volume;

  CandleData({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    this.volume,
  });

  // Конвертация из массива цен в свечи (агрегация)
  static List<CandleData> fromPricePoints(
      List<dynamic> prices, int candleCount) {
    if (prices.isEmpty) return [];

    final candles = <CandleData>[];
    final pointsPerCandle = (prices.length / candleCount).ceil();

    for (int i = 0; i < prices.length; i += pointsPerCandle) {
      final end = (i + pointsPerCandle).clamp(0, prices.length);
      final chunk = prices.sublist(i, end);

      if (chunk.isEmpty) continue;

      final timestamp = chunk.first[0] as int;
      final chunkPrices = chunk.map((p) => (p[1] as num).toDouble()).toList();

      candles.add(CandleData(
        time: DateTime.fromMillisecondsSinceEpoch(timestamp),
        open: chunkPrices.first,
        high: chunkPrices.reduce((a, b) => a > b ? a : b),
        low: chunkPrices.reduce((a, b) => a < b ? a : b),
        close: chunkPrices.last,
      ));
    }

    return candles;
  }
}
