import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/portfolio.dart';
import '../services/demo_trading_service.dart';

// Провайдер сервиса
final demoTradingServiceProvider = Provider<DemoTradingService>((ref) {
  return DemoTradingService();
});

// Провайдер портфолио
final portfolioProvider =
    StateNotifierProvider<PortfolioNotifier, AsyncValue<Portfolio>>((ref) {
  return PortfolioNotifier(ref.read(demoTradingServiceProvider));
});

class PortfolioNotifier extends StateNotifier<AsyncValue<Portfolio>> {
  final DemoTradingService _service;

  PortfolioNotifier(this._service) : super(const AsyncValue.loading()) {
    _loadPortfolio();
  }

  Future<void> _loadPortfolio() async {
    try {
      final portfolio = await _service.loadPortfolio();
      state = AsyncValue.data(portfolio);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> buy({
    required String coinId,
    required String coinName,
    required String coinSymbol,
    required double price,
    required double amount,
  }) async {
    final currentPortfolio = state.value;
    if (currentPortfolio == null) return;

    try {
      final newPortfolio = await _service.buy(
        currentPortfolio: currentPortfolio,
        coinId: coinId,
        coinName: coinName,
        coinSymbol: coinSymbol,
        price: price,
        amount: amount,
      );
      state = AsyncValue.data(newPortfolio);
    } catch (e, st) {
      // Не меняем состояние при ошибке, просто пробрасываем исключение
      rethrow;
    }
  }

  Future<void> sell({
    required String coinId,
    required String coinName,
    required String coinSymbol,
    required double price,
    required double amount,
  }) async {
    final currentPortfolio = state.value;
    if (currentPortfolio == null) return;

    try {
      final newPortfolio = await _service.sell(
        currentPortfolio: currentPortfolio,
        coinId: coinId,
        coinName: coinName,
        coinSymbol: coinSymbol,
        price: price,
        amount: amount,
      );
      state = AsyncValue.data(newPortfolio);
    } catch (e, st) {
      rethrow;
    }
  }

  Future<void> reset() async {
    try {
      final newPortfolio = await _service.resetPortfolio();
      state = AsyncValue.data(newPortfolio);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Position? getPosition(String coinId) {
    final portfolio = state.value;
    if (portfolio == null) return null;
    return _service.getPosition(portfolio, coinId);
  }
}
