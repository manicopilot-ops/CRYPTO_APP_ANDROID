import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/coin_provider.dart';
import '../widgets/price_chart.dart';

class CoinComparisonScreen extends ConsumerStatefulWidget {
  const CoinComparisonScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CoinComparisonScreen> createState() =>
      _CoinComparisonScreenState();
}

class _CoinComparisonScreenState extends ConsumerState<CoinComparisonScreen> {
  final List<String> _selectedCoins = ['bitcoin', 'ethereum'];
  String _timeframe = '7';

  @override
  Widget build(BuildContext context) {
    final coins = ref.watch(coinListProvider);
    final marketsAsync = ref.watch(marketProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare Coins'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _selectedCoins.length < 3
                ? () => _showAddCoinDialog(coins)
                : null,
            tooltip: 'Add Coin',
          ),
        ],
      ),
      body: marketsAsync.when(
        data: (markets) {
          final map = {for (var m in markets) m.id: m};
          final selectedMarkets =
              _selectedCoins.map((id) => map[id]).whereType<dynamic>().toList();

          if (selectedMarkets.isEmpty) {
            return const Center(child: Text('No coins selected'));
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Coin selector chips
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Wrap(
                    spacing: 8,
                    children: _selectedCoins.map((coinId) {
                      final coin = coins.firstWhere((c) => c['id'] == coinId);
                      return Chip(
                        avatar: CircleAvatar(
                          child: Text(
                              coin['symbol']!.substring(0, 1).toUpperCase()),
                        ),
                        label: Text(coin['name']!),
                        onDeleted: _selectedCoins.length > 1
                            ? () {
                                setState(() {
                                  _selectedCoins.remove(coinId);
                                });
                              }
                            : null,
                      );
                    }).toList(),
                  ),
                ),

                // Timeframe selector
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTimeframeButton('1', '1 Day'),
                      const SizedBox(width: 8),
                      _buildTimeframeButton('7', '7 Days'),
                      const SizedBox(width: 8),
                      _buildTimeframeButton('30', '30 Days'),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Comparison table
                _buildComparisonTable(selectedMarkets, coins),

                const SizedBox(height: 24),

                // Charts
                ...selectedMarkets.map((market) {
                  final coin = coins.firstWhere((c) => c['id'] == market.id);
                  final pricesAsync = ref
                      .watch(pricesFutureProvider('${market.id}|$_timeframe'));

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  child: Text(
                                    coin['symbol']!
                                        .substring(0, 1)
                                        .toUpperCase(),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  coin['name']!,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 200,
                              child: pricesAsync.when(
                                data: (points) => points.isEmpty
                                    ? const Center(child: Text('No data'))
                                    : PriceChart(
                                        points: points,
                                        chartType: 'price',
                                      ),
                                loading: () => const Center(
                                    child: CircularProgressIndicator()),
                                error: (e, st) =>
                                    Center(child: Text('Error: $e')),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),

                const SizedBox(height: 16),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildTimeframeButton(String value, String label) {
    final isSelected = _timeframe == value;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _timeframe = value;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
        foregroundColor: isSelected ? Colors.white : Colors.black,
      ),
      child: Text(label),
    );
  }

  Widget _buildComparisonTable(
      List<dynamic> markets, List<Map<String, String>> coins) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final compactFormatter = NumberFormat.compact();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: DataTable(
          columns: [
            const DataColumn(label: Text('Metric')),
            ...markets.map((market) {
              final coin = coins.firstWhere((c) => c['id'] == market.id);
              return DataColumn(
                label: Text(
                  coin['symbol']!.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            }).toList(),
          ],
          rows: [
            DataRow(cells: [
              const DataCell(Text('Rank')),
              ...markets.map((m) => DataCell(Text('#${m.rank}'))).toList(),
            ]),
            DataRow(cells: [
              const DataCell(Text('Price')),
              ...markets.map((m) {
                return DataCell(Text(formatter.format(m.currentPrice)));
              }).toList(),
            ]),
            DataRow(cells: [
              const DataCell(Text('24h Change')),
              ...markets.map((m) {
                final change = m.priceChangePercentage24h ?? 0;
                return DataCell(
                  Text(
                    '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: change >= 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ]),
            DataRow(cells: [
              const DataCell(Text('Market Cap')),
              ...markets.map((m) {
                return DataCell(
                    Text('\$${compactFormatter.format(m.marketCap)}'));
              }).toList(),
            ]),
            DataRow(cells: [
              const DataCell(Text('Volume 24h')),
              ...markets.map((m) {
                return DataCell(
                    Text('\$${compactFormatter.format(m.totalVolume)}'));
              }).toList(),
            ]),
          ],
        ),
      ),
    );
  }

  void _showAddCoinDialog(List<Map<String, String>> coins) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Coin to Compare'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: coins.length,
              itemBuilder: (context, index) {
                final coin = coins[index];
                final isSelected = _selectedCoins.contains(coin['id']);

                if (isSelected) return const SizedBox.shrink();

                return ListTile(
                  leading: CircleAvatar(
                    child: Text(coin['symbol']!.substring(0, 1).toUpperCase()),
                  ),
                  title: Text(coin['name']!),
                  subtitle: Text(coin['symbol']!.toUpperCase()),
                  onTap: () {
                    setState(() {
                      _selectedCoins.add(coin['id']!);
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}
