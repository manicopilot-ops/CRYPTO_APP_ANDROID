import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/market_info.dart';
import '../providers/coin_provider.dart';
import '../widgets/price_chart.dart';

class CoinDetailScreen extends ConsumerStatefulWidget {
  const CoinDetailScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CoinDetailScreen> createState() => _CoinDetailScreenState();
}

class _CoinDetailScreenState extends ConsumerState<CoinDetailScreen> {
  int days = 7;

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, String>;
    final id = args['id']!;
    final name = args['name']!;

    final marketAsync = ref.watch(marketProvider);
    final asyncPrices = ref.watch(pricesFutureProvider('$id|$days'));

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: marketAsync.when(
        data: (markets) {
          final mi = markets.firstWhere(
            (m) => m.id == id,
            orElse: () =>
                MarketInfo(id: id, name: name, symbol: '', currentPrice: 0.0),
          );

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left info panel
                Container(
                  width: 360,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.0),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(mi.name,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12)),
                            child: Text(mi.symbol,
                                style: const TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        NumberFormat.simpleCurrency().format(mi.currentPrice),
                        style: const TextStyle(
                            fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        mi.priceChange24h != null
                            ? '${mi.priceChange24h!.toStringAsFixed(2)}%'
                            : '-',
                        style: TextStyle(
                            color: (mi.priceChange24h ?? 0) >= 0
                                ? Colors.green
                                : Colors.red),
                      ),
                      const SizedBox(height: 16),
                      if (mi.low24h != null && mi.high24h != null) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(NumberFormat.simpleCurrency()
                                .format(mi.low24h)),
                            const Text('24h Range',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.black54)),
                            Text(NumberFormat.simpleCurrency()
                                .format(mi.high24h)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        LayoutBuilder(builder: (context, constraints) {
                          final low = mi.low24h!;
                          final high = mi.high24h!;
                          final pos = ((mi.currentPrice - low) / (high - low))
                              .clamp(0.0, 1.0);
                          return Stack(
                            children: [
                              Container(
                                height: 8,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(4)),
                              ),
                              Container(
                                height: 8,
                                width: constraints.maxWidth * pos,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                      colors: [Colors.yellow, Colors.green]),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          );
                        }),
                        const SizedBox(height: 12),
                      ],
                      const Text('Market stats',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _statRow(
                          'Market Cap',
                          mi.marketCap != null
                              ? '\$' +
                                  NumberFormat.compact().format(mi.marketCap)
                              : '—'),
                      _statRow(
                          '24h Volume',
                          mi.volume24h != null
                              ? '\$' +
                                  NumberFormat.compact().format(mi.volume24h)
                              : '—'),
                      _statRow(
                          'Circulating Supply',
                          mi.circulatingSupply != null
                              ? NumberFormat.compact()
                                  .format(mi.circulatingSupply)
                              : '—'),
                      _statRow(
                          'Total Supply',
                          mi.totalSupply != null
                              ? NumberFormat.compact().format(mi.totalSupply)
                              : '—'),
                      _statRow(
                          'Max Supply',
                          mi.maxSupply != null
                              ? NumberFormat.compact().format(mi.maxSupply)
                              : '—'),
                      const SizedBox(height: 12),
                      const Text(
                          'Информационный просмотр — торговые операции не поддерживаются.',
                          style: TextStyle(color: Colors.black54)),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Right panel: chart + controls
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // timeframe buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          for (final d in [1, 7, 30])
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4.0),
                              child: ElevatedButton(
                                onPressed: () => setState(() => days = d),
                                child: Text('${d}d'),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // chart area
                      Expanded(
                        child: asyncPrices.when(
                          data: (points) => points.isEmpty
                              ? const Center(child: Text('No data'))
                              : PriceChart(points: points),
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (e, st) => SingleChildScrollView(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('Failed to load price data',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text(e.toString()),
                                const SizedBox(height: 8),
                                Text(st.toString(),
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey)),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: () => ref.refresh(
                                      pricesFutureProvider('$id|$days')),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Failed to load market info: $e')),
      ),
    );
  }
}

Widget _statRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );
}
