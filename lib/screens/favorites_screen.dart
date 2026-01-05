import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/coin_provider.dart';
import '../providers/favorites_provider.dart';
import '../widgets/sparkline.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritesProvider);
    final marketsAsync = ref.watch(marketProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Избранное'),
        automaticallyImplyLeading: false,
      ),
      body: favoritesAsync.when(
        data: (favoriteIds) {
          if (favoriteIds.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_border, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('Нет избранных монет',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text('Нажмите на звездочку чтобы добавить',
                      style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            );
          }

          return marketsAsync.when(
            data: (markets) {
              final favoriteMarkets =
                  markets.where((m) => favoriteIds.contains(m.id)).toList();

              if (favoriteMarkets.isEmpty) {
                return const Center(child: Text('Loading favorite coins...'));
              }

              return ListView.separated(
                itemCount: favoriteMarkets.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final mi = favoriteMarkets[i];

                  return ListTile(
                    leading: CircleAvatar(
                        child: Text(mi.symbol.substring(0, 1).toUpperCase())),
                    title: Text(mi.name),
                    subtitle: Text(mi.symbol.toUpperCase()),
                    trailing: SizedBox(
                      width: 200,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Remove from favorites
                          IconButton(
                            icon: const Icon(Icons.star,
                                color: Colors.amber, size: 20),
                            onPressed: () async {
                              final service =
                                  ref.read(favoritesServiceProvider);
                              await service.removeFavorite(mi.id);
                              ref.invalidate(favoritesProvider);
                              ref.invalidate(isFavoriteProvider(mi.id));
                            },
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
                        arguments: {'id': mi.id, 'name': mi.name}),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
