import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/price_point.dart';
import '../services/coingecko_service.dart';
import '../models/market_info.dart';

final coinListProvider = Provider<List<Map<String, String>>>((ref) => [
      // Top Cryptocurrencies
      {
        'id': 'bitcoin',
        'name': 'Bitcoin',
        'symbol': 'BTC',
        'category': 'crypto'
      },
      {
        'id': 'ethereum',
        'name': 'Ethereum',
        'symbol': 'ETH',
        'category': 'crypto'
      },
      {
        'id': 'tether',
        'name': 'Tether',
        'symbol': 'USDT',
        'category': 'crypto'
      },
      {
        'id': 'binancecoin',
        'name': 'BNB',
        'symbol': 'BNB',
        'category': 'crypto'
      },
      {'id': 'solana', 'name': 'Solana', 'symbol': 'SOL', 'category': 'crypto'},
      {'id': 'ripple', 'name': 'XRP', 'symbol': 'XRP', 'category': 'crypto'},
      {
        'id': 'usd-coin',
        'name': 'USD Coin',
        'symbol': 'USDC',
        'category': 'crypto'
      },
      {
        'id': 'cardano',
        'name': 'Cardano',
        'symbol': 'ADA',
        'category': 'crypto'
      },
      {
        'id': 'dogecoin',
        'name': 'Dogecoin',
        'symbol': 'DOGE',
        'category': 'crypto'
      },
      {
        'id': 'chainlink',
        'name': 'Chainlink',
        'symbol': 'LINK',
        'category': 'crypto'
      },
      {
        'id': 'polygon',
        'name': 'Polygon',
        'symbol': 'MATIC',
        'category': 'crypto'
      },
      {
        'id': 'litecoin',
        'name': 'Litecoin',
        'symbol': 'LTC',
        'category': 'crypto'
      },
      {
        'id': 'polkadot',
        'name': 'Polkadot',
        'symbol': 'DOT',
        'category': 'crypto'
      },
      {
        'id': 'avalanche-2',
        'name': 'Avalanche',
        'symbol': 'AVAX',
        'category': 'crypto'
      },
      {
        'id': 'shiba-inu',
        'name': 'Shiba Inu',
        'symbol': 'SHIB',
        'category': 'crypto'
      },
      {
        'id': 'uniswap',
        'name': 'Uniswap',
        'symbol': 'UNI',
        'category': 'crypto'
      },
      {
        'id': 'cosmos',
        'name': 'Cosmos',
        'symbol': 'ATOM',
        'category': 'crypto'
      },
      {'id': 'monero', 'name': 'Monero', 'symbol': 'XMR', 'category': 'crypto'},
      {'id': 'aptos', 'name': 'Aptos', 'symbol': 'APT', 'category': 'crypto'},

      // Precious Metals
      {
        'id': 'paxos-gold',
        'name': 'PAX Gold',
        'symbol': 'PAXG',
        'category': 'metals'
      },
      {
        'id': 'tether-gold',
        'name': 'Tether Gold',
        'symbol': 'XAUT',
        'category': 'metals'
      },

      // Stablecoins
      {'id': 'dai', 'name': 'Dai', 'symbol': 'DAI', 'category': 'fiat'},
      {
        'id': 'binance-usd',
        'name': 'Binance USD',
        'symbol': 'BUSD',
        'category': 'fiat'
      },
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
