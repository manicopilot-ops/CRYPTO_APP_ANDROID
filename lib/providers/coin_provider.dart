import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/price_point.dart';
import '../services/coingecko_service.dart';
import '../models/market_info.dart';

final coinListProvider = Provider<List<Map<String, String>>>((ref) => [
      {'id': 'bitcoin', 'name': 'Bitcoin', 'symbol': 'BTC'},
      {'id': 'ethereum', 'name': 'Ethereum', 'symbol': 'ETH'},
      {'id': 'litecoin', 'name': 'Litecoin', 'symbol': 'LTC'},
    ]);

final pricesFutureProvider = FutureProvider.family<List<PricePoint>, String>(
  (ref, key) async {
    final parts = key.split('|');
    final id = parts[0];
    final days = int.parse(parts[1]);
    return CoinGeckoService.fetchMarketChart(id, 'usd', days);
  },
);

final marketProvider = FutureProvider<List<MarketInfo>>((ref) async {
  final coins = ref.watch(coinListProvider);
  final ids = coins.map((c) => c['id']!).toList();
  return CoinGeckoService.fetchMarkets(ids);
});
