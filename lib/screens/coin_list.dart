import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/coin_provider.dart';
import '../providers/favorites_provider.dart';
import '../widgets/sparkline.dart';

class CoinListScreen extends ConsumerStatefulWidget {
  const CoinListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CoinListScreen> createState() => _CoinListScreenState();
}

class _CoinListScreenState extends ConsumerState<CoinListScreen> {
  String _sortBy = 'rank';
  String _categoryFilter = 'all'; // all, crypto, metals, fiat

  @override
  Widget build(BuildContext context) {
    final coins = ref.watch(coinListProvider);
    final marketsAsync = ref.watch(marketProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Рынок'),
        automaticallyImplyLeading: false,
        actions: [
          // Notifications button
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Price Alerts',
            onPressed: () => Navigator.pushNamed(context, '/alerts'),
          ),
          // Sort button
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort',
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'rank',
                child: Row(
                  children: [
                    Icon(Icons.numbers, size: 20),
                    SizedBox(width: 8),
                    Text('By Rank'),
                    if (_sortBy == 'rank') ...[
                      Spacer(),
                      Icon(Icons.check, size: 20, color: Colors.blue),
                    ],
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'price',
                child: Row(
                  children: [
                    Icon(Icons.attach_money, size: 20),
                    SizedBox(width: 8),
                    Text('By Price'),
                    if (_sortBy == 'price') ...[
                      Spacer(),
                      Icon(Icons.check, size: 20, color: Colors.blue),
                    ],
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'change',
                child: Row(
                  children: [
                    Icon(Icons.trending_up, size: 20),
                    SizedBox(width: 8),
                    Text('By 24h Change'),
                    if (_sortBy == 'change') ...[
                      Spacer(),
                      Icon(Icons.check, size: 20, color: Colors.blue),
                    ],
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'volume',
                child: Row(
                  children: [
                    Icon(Icons.bar_chart, size: 20),
                    SizedBox(width: 8),
                    Text('By Volume'),
                    if (_sortBy == 'volume') ...[
                      Spacer(),
                      Icon(Icons.check, size: 20, color: Colors.blue),
                    ],
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'marketCap',
                child: Row(
                  children: [
                    Icon(Icons.pie_chart, size: 20),
                    SizedBox(width: 8),
                    Text('By Market Cap'),
                    if (_sortBy == 'marketCap') ...[
                      Spacer(),
                      Icon(Icons.check, size: 20, color: Colors.blue),
                    ],
                  ],
                ),
              ),
            ],
          ),
          // Category filter
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter by Category',
            onSelected: (value) {
              setState(() {
                _categoryFilter = value;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'all',
                child: Row(
                  children: [
                    Icon(Icons.all_inclusive, size: 20),
                    SizedBox(width: 8),
                    Text('All Assets'),
                    if (_categoryFilter == 'all') ...[
                      Spacer(),
                      Icon(Icons.check, size: 20, color: Colors.blue),
                    ],
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'crypto',
                child: Row(
                  children: [
                    Icon(Icons.currency_bitcoin, size: 20),
                    SizedBox(width: 8),
                    Text('Crypto'),
                    if (_categoryFilter == 'crypto') ...[
                      Spacer(),
                      Icon(Icons.check, size: 20, color: Colors.blue),
                    ],
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'metals',
                child: Row(
                  children: [
                    Icon(Icons.workspaces, size: 20),
                    SizedBox(width: 8),
                    Text('Precious Metals'),
                    if (_categoryFilter == 'metals') ...[
                      Spacer(),
                      Icon(Icons.check, size: 20, color: Colors.blue),
                    ],
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'fiat',
                child: Row(
                  children: [
                    Icon(Icons.attach_money, size: 20),
                    SizedBox(width: 8),
                    Text('Stablecoins'),
                    if (_categoryFilter == 'fiat') ...[
                      Spacer(),
                      Icon(Icons.check, size: 20, color: Colors.blue),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: marketsAsync.when(
        data: (markets) {
          // build list by mapping markets to coins order
          final map = {for (var m in markets) m.id: m};

          // Filter by category first
          var filteredCoins = _categoryFilter == 'all'
              ? coins
              : coins.where((c) => c['category'] == _categoryFilter).toList();

          // Sort coins
          if (_sortBy != 'rank') {
            filteredCoins = List.from(filteredCoins);
            filteredCoins.sort((a, b) {
              final aMarket = map[a['id']];
              final bMarket = map[b['id']];

              if (aMarket == null || bMarket == null) return 0;

              switch (_sortBy) {
                case 'price':
                  return bMarket.currentPrice.compareTo(aMarket.currentPrice);
                case 'change':
                  return (bMarket.priceChange24h ?? 0)
                      .compareTo(aMarket.priceChange24h ?? 0);
                case 'volume':
                  return (bMarket.volume24h ?? 0)
                      .compareTo(aMarket.volume24h ?? 0);
                case 'marketCap':
                  return (bMarket.marketCap ?? 0)
                      .compareTo(aMarket.marketCap ?? 0);
                default:
                  return 0;
              }
            });
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(marketProvider);
            },
            child: ListView.builder(
              itemCount: filteredCoins.length,
              itemBuilder: (context, i) {
                final c = filteredCoins[i];
                final mi = map[c['id']];
                final favoriteAsync = ref.watch(isFavoriteProvider(c['id']!));

                return ListTile(
                  leading:
                      CircleAvatar(child: Text(c['symbol']!.substring(0, 1))),
                  title: Text(c['name']!),
                  subtitle: Text(c['symbol']!),
                  trailing: mi == null
                      ? const Icon(Icons.chevron_right)
                      : SizedBox(
                          width: 200,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Favorite icon
                              favoriteAsync.when(
                                data: (isFav) => IconButton(
                                  icon: Icon(
                                    isFav ? Icons.star : Icons.star_border,
                                    color: isFav ? Colors.amber : Colors.grey,
                                    size: 20,
                                  ),
                                  onPressed: () async {
                                    final service =
                                        ref.read(favoritesServiceProvider);
                                    await service.toggleFavorite(c['id']!);
                                    ref.invalidate(favoritesProvider);
                                    ref.invalidate(
                                        isFavoriteProvider(c['id']!));
                                  },
                                ),
                                loading: () => const SizedBox(width: 20),
                                error: (_, __) => const SizedBox(width: 20),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                      '\$${mi.currentPrice.toStringAsFixed(2)}'),
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
                  onTap: () => Navigator.pushNamed(context, '/coin-detail',
                      arguments: {'id': c['id']!, 'name': c['name']!}),
                );
              },
            ),
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
