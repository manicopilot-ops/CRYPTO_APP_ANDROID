import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/portfolio.dart';

class DemoTradingService {
  static const String _portfolioKey = 'demo_portfolio';

  // Загрузить портфолио из хранилища
  Future<Portfolio> loadPortfolio() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_portfolioKey);

      if (jsonString == null) {
        // Если портфолио не существует, создаем новое с начальным балансом
        return Portfolio.initial();
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return Portfolio.fromJson(json);
    } catch (e) {
      print('Error loading portfolio: $e');
      return Portfolio.initial();
    }
  }

  // Сохранить портфолио
  Future<void> savePortfolio(Portfolio portfolio) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(portfolio.toJson());
      await prefs.setString(_portfolioKey, jsonString);
    } catch (e) {
      print('Error saving portfolio: $e');
      throw Exception('Failed to save portfolio');
    }
  }

  // Купить криптовалюту
  Future<Portfolio> buy({
    required Portfolio currentPortfolio,
    required String coinId,
    required String coinName,
    required String coinSymbol,
    required double price,
    required double amount,
  }) async {
    final total = price * amount;

    // Проверяем достаточно ли средств
    if (currentPortfolio.balance < total) {
      throw Exception(
          'Недостаточно средств. Баланс: \$${currentPortfolio.balance.toStringAsFixed(2)}');
    }

    // Создаем новую сделку
    final trade = Trade(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      coinId: coinId,
      coinName: coinName,
      coinSymbol: coinSymbol,
      type: TradeType.buy,
      price: price,
      amount: amount,
      total: total,
      timestamp: DateTime.now(),
    );

    // Обновляем баланс
    final newBalance = currentPortfolio.balance - total;

    // Обновляем позицию
    final positions = List<Position>.from(currentPortfolio.positions);
    final existingPositionIndex =
        positions.indexWhere((p) => p.coinId == coinId);

    if (existingPositionIndex >= 0) {
      // Обновляем существующую позицию
      final existingPosition = positions[existingPositionIndex];
      final totalAmount = existingPosition.amount + amount;
      final totalCost =
          (existingPosition.averagePrice * existingPosition.amount) + total;
      final newAveragePrice = totalCost / totalAmount;

      positions[existingPositionIndex] = existingPosition.copyWith(
        amount: totalAmount,
        averagePrice: newAveragePrice,
      );
    } else {
      // Создаем новую позицию
      positions.add(Position(
        coinId: coinId,
        coinName: coinName,
        coinSymbol: coinSymbol,
        amount: amount,
        averagePrice: price,
      ));
    }

    // Обновляем историю сделок
    final tradeHistory = List<Trade>.from(currentPortfolio.tradeHistory)
      ..add(trade);

    // Создаем новое портфолио
    final newPortfolio = currentPortfolio.copyWith(
      balance: newBalance,
      positions: positions,
      tradeHistory: tradeHistory,
    );

    // Сохраняем
    await savePortfolio(newPortfolio);

    return newPortfolio;
  }

  // Продать криптовалюту
  Future<Portfolio> sell({
    required Portfolio currentPortfolio,
    required String coinId,
    required String coinName,
    required String coinSymbol,
    required double price,
    required double amount,
  }) async {
    // Находим позицию
    final existingPositionIndex =
        currentPortfolio.positions.indexWhere((p) => p.coinId == coinId);

    if (existingPositionIndex < 0) {
      throw Exception('У вас нет этой криптовалюты');
    }

    final existingPosition = currentPortfolio.positions[existingPositionIndex];

    // Проверяем достаточно ли количества
    if (existingPosition.amount < amount) {
      throw Exception(
          'Недостаточно монет. У вас: ${existingPosition.amount.toStringAsFixed(8)}');
    }

    final total = price * amount;

    // Создаем новую сделку
    final trade = Trade(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      coinId: coinId,
      coinName: coinName,
      coinSymbol: coinSymbol,
      type: TradeType.sell,
      price: price,
      amount: amount,
      total: total,
      timestamp: DateTime.now(),
    );

    // Обновляем баланс
    final newBalance = currentPortfolio.balance + total;

    // Обновляем позицию
    final positions = List<Position>.from(currentPortfolio.positions);
    final newAmount = existingPosition.amount - amount;

    if (newAmount > 0.0000001) {
      // Обновляем позицию
      positions[existingPositionIndex] =
          existingPosition.copyWith(amount: newAmount);
    } else {
      // Удаляем позицию если количество близко к нулю
      positions.removeAt(existingPositionIndex);
    }

    // Обновляем историю сделок
    final tradeHistory = List<Trade>.from(currentPortfolio.tradeHistory)
      ..add(trade);

    // Создаем новое портфолио
    final newPortfolio = currentPortfolio.copyWith(
      balance: newBalance,
      positions: positions,
      tradeHistory: tradeHistory,
    );

    // Сохраняем
    await savePortfolio(newPortfolio);

    return newPortfolio;
  }

  // Сбросить портфолио к начальному состоянию
  Future<Portfolio> resetPortfolio() async {
    final newPortfolio = Portfolio.initial();
    await savePortfolio(newPortfolio);
    return newPortfolio;
  }

  // Получить позицию для конкретной монеты
  Position? getPosition(Portfolio portfolio, String coinId) {
    try {
      return portfolio.positions.firstWhere((p) => p.coinId == coinId);
    } catch (e) {
      return null;
    }
  }
}
