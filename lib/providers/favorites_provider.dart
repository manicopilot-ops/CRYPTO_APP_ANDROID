import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/favorites_service.dart';

final favoritesServiceProvider = Provider((ref) => FavoritesService());

final favoritesProvider = FutureProvider<Set<String>>((ref) async {
  final service = ref.watch(favoritesServiceProvider);
  return await service.getFavorites();
});

final isFavoriteProvider =
    FutureProvider.family<bool, String>((ref, coinId) async {
  final service = ref.watch(favoritesServiceProvider);
  return await service.isFavorite(coinId);
});
