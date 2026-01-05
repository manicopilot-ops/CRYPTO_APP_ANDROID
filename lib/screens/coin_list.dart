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

class _CoinListScreenState extends ConsumerState<CoinListScreen>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  String _sortBy = 'rank';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coins = ref.watch(coinListProvider);
    final marketsAsync = ref.watch(marketProvider);
    final favorites = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cryptocurrencies'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All', icon: Icon(Icons.list)),
            Tab(text: 'Favorites', icon: Icon(Icons.star)),
            Tab(text: 'Gainers', icon: Icon(Icons.trending_up)),
            Tab(text: 'Losers', icon: Icon(Icons.trending_down)),
          ],
        ),
        actions: [
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
          IconButton(
            icon: const Icon(Icons.star),
            onPressed: () => Navigator.pushNamed(context, '/favorites'),
            tooltip: 'Favorites',
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.pushNamed(context, '/alerts'),
            tooltip: 'Price Alerts',
          ),
          IconButton(
            icon: const Icon(Icons.currency_exchange),
            onPressed: () => Navigator.pushNamed(context, '/converter'),
            tooltip: 'Currency Converter',
          ),
        ],
      ),
      body: marketsAsync.when(
        data: (markets) {
          // build list by mapping markets to coins order
          final map = {for (var m in markets) m.id: m};

          // Filter coins based on search query
          var filteredCoins = _searchQuery.isEmpty
              ? coins
              : coins.where((c) {
                  final query = _searchQuery.toLowerCase();
                  return c['name']!.toLowerCase().contains(query) ||
                      c['symbol']!.toLowerCase().contains(query) ||
                      c['id']!.toLowerCase().contains(query);
                }).toList();

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

          // Filter for Favorites tab
          final favoriteCoins = favorites.when(
            data: (favs) =>
                filteredCoins.where((c) => favs.contains(c['id'])).toList(),
            loading: () => <Map<String, String>>[],
            error: (_, __) => <Map<String, String>>[],
          );

          // Filter for Gainers tab (top 50 by 24h change)
          final gainerCoins = List<Map<String, String>>.from(filteredCoins);
          gainerCoins.sort((a, b) {
            final aMarket = map[a['id']];
            final bMarket = map[b['id']];
            if (aMarket == null || bMarket == null) return 0;
            return (bMarket.priceChange24h ?? 0)
                .compareTo(aMarket.priceChange24h ?? 0);
          });
          final topGainers = gainerCoins.take(50).toList();

          // Filter for Losers tab (bottom 50 by 24h change)
          final loserCoins = List<Map<String, String>>.from(filteredCoins);
          loserCoins.sort((a, b) {
            final aMarket = map[a['id']];
            final bMarket = map[b['id']];
            if (aMarket == null || bMarket == null) return 0;
            return (aMarket.priceChange24h ?? 0)
                .compareTo(bMarket.priceChange24h ?? 0);
          });
          final topLosers = loserCoins.take(50).toList();

          return Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search coins...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              // TabBarView with lists
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // All tab
                    _buildCoinList(filteredCoins, map, 'All'),
                    // Favorites tab
                    _buildCoinList(favoriteCoins, map, 'Favorites'),
                    // Gainers tab
                    _buildCoinList(topGainers, map, 'Gainers'),
                    // Losers tab
                    _buildCoinList(topLosers, map, 'Losers'),
                  ],
                ),
              ),
            ],
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

  Widget _buildCoinList(List<Map<String, String>> coinsList,
      Map<String, dynamic> map, String tabName) {
    if (coinsList.isEmpty) {
      String emptyMessage;
      IconData emptyIcon;

      switch (tabName) {
        case 'Favorites':
          emptyMessage = 'No favorites yet';
          emptyIcon = Icons.star_border;
          break;
        case 'Gainers':
          emptyMessage = 'No gainers found';
          emptyIcon = Icons.trending_up;
          break;
        case 'Losers':
          emptyMessage = 'No losers found';
          emptyIcon = Icons.trending_down;
          break;
        default:
          emptyMessage = 'No coins found';
          emptyIcon = Icons.search_off;
      }

      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(emptyIcon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(emptyMessage,
                style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            const SizedBox(height: 8),
            if (tabName == 'All')
              Text('Try a different search term',
                  style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: coinsList.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final c = coinsList[i];
        final mi = map[c['id']];
        final favoriteAsync = ref.watch(isFavoriteProvider(c['id']!));

        return ListTile(
          leading: CircleAvatar(child: Text(c['symbol']!.substring(0, 1))),
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
                            final service = ref.read(favoritesServiceProvider);
                            await service.toggleFavorite(c['id']!);
                            ref.invalidate(favoritesProvider);
                            ref.invalidate(isFavoriteProvider(c['id']!));
                          },
                        ),
                        loading: () => const SizedBox(width: 20),
                        error: (_, __) => const SizedBox(width: 20),
                      ),
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
  }
}
