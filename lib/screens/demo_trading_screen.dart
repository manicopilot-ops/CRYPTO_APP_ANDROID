import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/portfolio.dart';
import '../providers/demo_trading_provider.dart';
import '../providers/coin_provider.dart';

class DemoTradingScreen extends ConsumerWidget {
  const DemoTradingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolioAsync = ref.watch(portfolioProvider);
    final marketAsync = ref.watch(marketProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Демо-Трейдинг'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Сбросить портфолио',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Сбросить портфолио?'),
                  content: const Text(
                      'Это удалит все ваши позиции и вернет баланс к \$10,000'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Отмена'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        ref.read(portfolioProvider.notifier).reset();
                        Navigator.pop(context);
                      },
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Сбросить'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: portfolioAsync.when(
        data: (portfolio) => SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Баланс карточка
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const Text(
                          'ВИРТУАЛЬНЫЙ БАЛАНС',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          NumberFormat.simpleCurrency()
                              .format(portfolio.balance),
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 16),
                        marketAsync.when(
                          data: (markets) {
                            double portfolioValue = portfolio.balance;

                            for (final position in portfolio.positions) {
                              final market = markets.firstWhere(
                                (m) => m.id == position.coinId,
                                orElse: () => markets.first,
                              );
                              portfolioValue +=
                                  position.amount * market.currentPrice;
                            }

                            final totalPnL = portfolioValue - 10000.0;
                            final totalPnLPercent = (totalPnL / 10000.0) * 100;

                            return Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildStatItem(
                                      'Стоимость портфеля',
                                      NumberFormat.simpleCurrency()
                                          .format(portfolioValue),
                                    ),
                                    _buildStatItem(
                                      'Прибыль/Убыток',
                                      '${totalPnL >= 0 ? '+' : ''}${NumberFormat.simpleCurrency().format(totalPnL)}',
                                      color: totalPnL >= 0
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${totalPnLPercent >= 0 ? '+' : ''}${totalPnLPercent.toStringAsFixed(2)}%',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: totalPnLPercent >= 0
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            );
                          },
                          loading: () => const CircularProgressIndicator(),
                          error: (e, st) => Text('Ошибка: $e'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Позиции
                if (portfolio.positions.isNotEmpty) ...[
                  const Text(
                    'МОИ ПОЗИЦИИ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  marketAsync.when(
                    data: (markets) => ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: portfolio.positions.length,
                      itemBuilder: (context, index) {
                        final position = portfolio.positions[index];
                        final market = markets.firstWhere(
                          (m) => m.id == position.coinId,
                          orElse: () => markets.first,
                        );

                        final currentValue =
                            position.amount * market.currentPrice;
                        final costBasis =
                            position.amount * position.averagePrice;
                        final pnl = currentValue - costBasis;
                        final pnlPercent = (pnl / costBasis) * 100;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(position.coinSymbol[0]),
                            ),
                            title: Text(
                              position.coinName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    '${position.amount.toStringAsFixed(8)} ${position.coinSymbol}'),
                                Text(
                                  'Средняя: ${NumberFormat.simpleCurrency().format(position.averagePrice)}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                Text(
                                  'Текущая: ${NumberFormat.simpleCurrency().format(market.currentPrice)}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  NumberFormat.simpleCurrency()
                                      .format(currentValue),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '${pnl >= 0 ? '+' : ''}${pnlPercent.toStringAsFixed(2)}%',
                                  style: TextStyle(
                                    color: pnl >= 0 ? Colors.green : Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (e, st) => Text('Ошибка: $e'),
                  ),
                  const SizedBox(height: 24),
                ],

                // История сделок
                if (portfolio.tradeHistory.isNotEmpty) ...[
                  const Text(
                    'ИСТОРИЯ СДЕЛОК',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: portfolio.tradeHistory.length > 10
                        ? 10
                        : portfolio.tradeHistory.length,
                    itemBuilder: (context, index) {
                      // Показываем последние сделки первыми
                      final trade = portfolio.tradeHistory[
                          portfolio.tradeHistory.length - 1 - index];

                      final isBuy = trade.type == TradeType.buy;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isBuy ? Colors.green : Colors.red,
                            child: Icon(
                              isBuy ? Icons.arrow_downward : Icons.arrow_upward,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            '${isBuy ? 'Купить' : 'Продать'} ${trade.coinName}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  '${trade.amount.toStringAsFixed(8)} ${trade.coinSymbol}'),
                              Text(
                                'Цена: ${NumberFormat.simpleCurrency().format(trade.price)}',
                                style: const TextStyle(fontSize: 11),
                              ),
                              Text(
                                DateFormat('dd MMM yyyy, HH:mm')
                                    .format(trade.timestamp),
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.grey),
                              ),
                            ],
                          ),
                          trailing: Text(
                            NumberFormat.simpleCurrency().format(trade.total),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isBuy ? Colors.red : Colors.green,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],

                if (portfolio.positions.isEmpty &&
                    portfolio.tradeHistory.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(Icons.account_balance_wallet,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Начните торговать!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Выберите криптовалюту из списка и начните демо-трейдинг',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Ошибка: $e')),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
