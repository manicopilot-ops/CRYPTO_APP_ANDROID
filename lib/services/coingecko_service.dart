import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/price_point.dart';
import '../models/market_info.dart';

class CoinGeckoService {
  /// Fetch market chart prices for [id] (e.g. 'bitcoin'), [vsCurrency] (e.g. 'usd') and [days].
  static Future<List<PricePoint>> fetchMarketChart(
      String id, String vsCurrency, int days) async {
    final url = Uri.parse(
        'https://api.coingecko.com/api/v3/coins/$id/market_chart?vs_currency=$vsCurrency&days=$days');
    try {
      final res = await http.get(url).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) {
        throw Exception('Failed to load data: ${res.statusCode}');
      }
      final data = json.decode(res.body);
      final prices = (data['prices'] as List).map((p) {
        final t = DateTime.fromMillisecondsSinceEpoch((p[0] as num).toInt());
        final price = (p[1] as num).toDouble();
        return PricePoint(time: t, price: price);
      }).toList();
      return prices;
    } catch (e) {
      throw Exception('CoinGecko market_chart error: $e');
    }
  }

  /// Fetch market info for multiple coins (current price, 24h change, sparkline)
  static Future<List<MarketInfo>> fetchMarkets(List<String> ids,
      {String vsCurrency = 'usd'}) async {
    if (ids.isEmpty) return [];
    final joined = ids.join(',');
    final url = Uri.parse(
        'https://api.coingecko.com/api/v3/coins/markets?vs_currency=$vsCurrency&ids=$joined&order=market_cap_desc&per_page=250&page=1&sparkline=true&price_change_percentage=24h');
    try {
      final res = await http.get(url).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) {
        throw Exception('Failed to load markets: ${res.statusCode}');
      }
      final data = json.decode(res.body) as List;
      return data.map((item) {
        final spark = <double>[];
        if (item['sparkline_in_7d'] != null &&
            item['sparkline_in_7d']['price'] != null) {
          spark.addAll((item['sparkline_in_7d']['price'] as List)
              .map((p) => (p as num).toDouble()));
        }
        return MarketInfo(
          id: item['id'] as String,
          name: item['name'] as String,
          symbol: (item['symbol'] as String).toUpperCase(),
          currentPrice: (item['current_price'] as num).toDouble(),
          priceChange24h: item['price_change_percentage_24h'] != null
              ? (item['price_change_percentage_24h'] as num).toDouble()
              : null,
          sparkline: spark,
          marketCap: item['market_cap'] != null
              ? (item['market_cap'] as num).toDouble()
              : null,
          volume24h: item['total_volume'] != null
              ? (item['total_volume'] as num).toDouble()
              : null,
          circulatingSupply: item['circulating_supply'] != null
              ? (item['circulating_supply'] as num).toDouble()
              : null,
          totalSupply: item['total_supply'] != null
              ? (item['total_supply'] as num).toDouble()
              : null,
          maxSupply: item['max_supply'] != null
              ? (item['max_supply'] as num).toDouble()
              : null,
          low24h: item['low_24h'] != null
              ? (item['low_24h'] as num).toDouble()
              : null,
          high24h: item['high_24h'] != null
              ? (item['high_24h'] as num).toDouble()
              : null,
        );
      }).toList();
    } catch (e) {
      throw Exception('CoinGecko markets error: $e');
    }
  }
}
