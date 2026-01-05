import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/price_point.dart';
import '../models/market_info.dart';

class CoinGeckoService {
  static int _requestCount = 0;
  static DateTime? _lastRequestTime;

  /// Add delay to avoid rate limiting
  static Future<void> _throttle() async {
    _requestCount++;
    final now = DateTime.now();

    if (_lastRequestTime != null) {
      final diff = now.difference(_lastRequestTime!);
      if (diff.inMilliseconds < 1500) {
        await Future.delayed(
            Duration(milliseconds: 1500 - diff.inMilliseconds));
      }
    }

    _lastRequestTime = DateTime.now();
  }

  /// Fetch market chart prices for [id] (e.g. 'bitcoin'), [vsCurrency] (e.g. 'usd') and [days].
  static Future<List<PricePoint>> fetchMarketChart(
      String id, String vsCurrency, int days) async {
    await _throttle();

    final url = Uri.parse(
        'https://api.coingecko.com/api/v3/coins/$id/market_chart?vs_currency=$vsCurrency&days=$days');

    // Retry logic for rate limiting
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        final res = await http.get(url).timeout(const Duration(seconds: 15));

        if (res.statusCode == 429) {
          // Rate limited - wait and retry
          await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
          continue;
        }

        if (res.statusCode != 200) {
          throw Exception('Failed to load data: ${res.statusCode}');
        }

        final data = json.decode(res.body);

        // Parse prices
        final pricesList = data['prices'] as List;
        final volumesList = data['total_volumes'] as List?;
        final marketCapsList = data['market_caps'] as List?;

        final prices = <PricePoint>[];
        for (int i = 0; i < pricesList.length; i++) {
          final priceData = pricesList[i];
          final t = DateTime.fromMillisecondsSinceEpoch(
              (priceData[0] as num).toInt());
          final price = (priceData[1] as num).toDouble();

          double? volume;
          if (volumesList != null && i < volumesList.length) {
            volume = (volumesList[i][1] as num).toDouble();
          }

          double? marketCap;
          if (marketCapsList != null && i < marketCapsList.length) {
            marketCap = (marketCapsList[i][1] as num).toDouble();
          }

          prices.add(PricePoint(
            time: t,
            price: price,
            volume: volume,
            marketCap: marketCap,
          ));
        }

        return prices;
      } catch (e) {
        if (attempt == 2) {
          throw Exception('CoinGecko market_chart error: $e');
        }
        // Wait before retry
        await Future.delayed(Duration(seconds: 1 * (attempt + 1)));
      }
    }

    throw Exception('Failed to load data after 3 attempts');
  }

  /// Fetch market info for multiple coins (current price, 24h change, sparkline)
  static Future<List<MarketInfo>> fetchMarkets(List<String> ids,
      {String vsCurrency = 'usd'}) async {
    if (ids.isEmpty) return [];

    await _throttle();

    final joined = ids.join(',');
    final url = Uri.parse(
        'https://api.coingecko.com/api/v3/coins/markets?vs_currency=$vsCurrency&ids=$joined&order=market_cap_desc&per_page=250&page=1&sparkline=true&price_change_percentage=24h');

    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        final res = await http.get(url).timeout(const Duration(seconds: 15));

        if (res.statusCode == 429) {
          await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
          continue;
        }

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
            priceChangePercentage24h:
                item['price_change_percentage_24h'] != null
                    ? (item['price_change_percentage_24h'] as num).toDouble()
                    : null,
            sparkline: spark,
            marketCap: item['market_cap'] != null
                ? (item['market_cap'] as num).toDouble()
                : null,
            totalVolume: item['total_volume'] != null
                ? (item['total_volume'] as num).toDouble()
                : null,
            volume24h: item['total_volume'] != null
                ? (item['total_volume'] as num).toDouble()
                : null,
            rank: item['market_cap_rank'] != null
                ? item['market_cap_rank'] as int
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
        if (attempt == 2) {
          throw Exception('CoinGecko markets error: $e');
        }
        await Future.delayed(Duration(seconds: 1 * (attempt + 1)));
      }
    }

    throw Exception('Failed to load markets after 3 attempts');
  }
}
