import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/coin_provider.dart';
import '../widgets/sparkline.dart';

class CoinListScreen extends ConsumerWidget {
  const CoinListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coins = ref.watch(coinListProvider);
    final marketsAsync = ref.watch(marketProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Cryptocurrencies')),
      body: marketsAsync.when(
        data: (markets) {
          // build list by mapping markets to coins order
          final map = {for (var m in markets) m.id: m};
          return ListView.separated(
            itemCount: coins.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final c = coins[i];
              final mi = map[c['id']];
              return ListTile(
                leading:
                    CircleAvatar(child: Text(c['symbol']!.substring(0, 1))),
                title: Text(c['name']!),
                subtitle: Text(c['symbol']!),
                trailing: mi == null
                    ? const Icon(Icons.chevron_right)
                    : SizedBox(
                        width: 140,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('\$${mi.currentPrice.toStringAsFixed(2)}'),
                                Text(
                                  mi.priceChange24h != null
                                      ? '${mi.priceChange24h!.toStringAsFixed(2)}%'
                                      : '-',
                                  style: TextStyle(
                                    color: (mi.priceChange24h ?? 0) >= 0
                                        ? Colors.green
                                        : Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            Sparkline(
                                values: mi.sparkline,
                                width: 60,
                                height: 36,
                                color: Colors.blue),
                          ],
                        ),
                      ),
                onTap: () => Navigator.pushNamed(context, '/detail',
                    arguments: {'id': c['id']!, 'name': c['name']!}),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Failed to load market data: $e'),
              const SizedBox(height: 8),
              ElevatedButton(
                  onPressed: () => ref.refresh(marketProvider),
                  child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}
