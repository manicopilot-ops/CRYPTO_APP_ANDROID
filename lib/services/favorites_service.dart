import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const String _key = 'favorite_coins';

  Future<Set<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList(_key) ?? [];
    return favorites.toSet();
  }

  Future<void> addFavorite(String coinId) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavorites();
    favorites.add(coinId);
    await prefs.setStringList(_key, favorites.toList());
  }

  Future<void> removeFavorite(String coinId) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavorites();
    favorites.remove(coinId);
    await prefs.setStringList(_key, favorites.toList());
  }

  Future<bool> isFavorite(String coinId) async {
    final favorites = await getFavorites();
    return favorites.contains(coinId);
  }

  Future<void> toggleFavorite(String coinId) async {
    if (await isFavorite(coinId)) {
      await removeFavorite(coinId);
    } else {
      await addFavorite(coinId);
    }
  }
}
