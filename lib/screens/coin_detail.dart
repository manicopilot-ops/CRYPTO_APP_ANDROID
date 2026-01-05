import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/market_info.dart';
import '../models/price_alert.dart';
import '../models/candle_data.dart';
import '../providers/coin_provider.dart';
import '../providers/price_alerts_provider.dart';
import '../providers/demo_trading_provider.dart';
import '../services/notification_service.dart';
import '../services/coingecko_service.dart';
import '../widgets/price_chart.dart';
import '../widgets/candlestick_chart.dart';

class CoinDetailScreen extends ConsumerStatefulWidget {
  const CoinDetailScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CoinDetailScreen> createState() => _CoinDetailScreenState();
}

class _CoinDetailScreenState extends ConsumerState<CoinDetailScreen> {
  int days = 7;
  bool _isPanelOpen = false;
  bool _isControlsVisible = true;
  String _chartType = 'price'; // 'price', 'volume', 'marketcap'
  String _chartStyle = 'line'; // 'line' или 'candle'
  bool _showTradingView = false; // Переключатель для TradingView
  WebViewController?
      _webViewController; // Nullable для отложенной инициализации

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, String>;
    final id = args['id']!;
    final name = args['name']!;

    final marketAsync = ref.watch(marketProvider);
    final asyncPrices = ref.watch(pricesFutureProvider('$id|$days'));

    return Scaffold(
      appBar: AppBar(
        title: Text(name, style: const TextStyle(fontSize: 16)),
        toolbarHeight: 48,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, size: 20),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
            tooltip: 'Price Alerts',
            onPressed: () => _showAlertsDialog(context, id, name),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: marketAsync.when(
        data: (markets) {
          final mi = markets.firstWhere(
            (m) => m.id == id,
            orElse: () =>
                MarketInfo(id: id, name: name, symbol: '', currentPrice: 0.0),
          );

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 700;
                final fmt = NumberFormat.simpleCurrency();
                final cmpFmt = NumberFormat.compact();

                // Both layouts now use sliding panel
                return Stack(
                  children: [
                    // Chart area (full screen)
                    AnimatedPadding(
                      duration: const Duration(milliseconds: 300),
                      padding: EdgeInsets.only(
                        left: isWide && _isPanelOpen ? 400 : 0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Toggle button для показа/скрытия настроек
                          Container(
                            color: const Color(0xFF2C2C3E),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Кнопка TradingView
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _showTradingView = !_showTradingView;
                                      if (_showTradingView) {
                                        // Инициализация WebView контроллера
                                        _webViewController = WebViewController()
                                          ..setJavaScriptMode(
                                              JavaScriptMode.unrestricted)
                                          ..loadRequest(Uri.parse(
                                              'https://www.tradingview.com/chart/?symbol=BINANCE:${mi.symbol.toUpperCase()}USDT&theme=dark&interval=D'));
                                      }
                                    });
                                  },
                                  icon: Icon(
                                      _showTradingView
                                          ? Icons.show_chart
                                          : Icons.candlestick_chart,
                                      size: 12),
                                  label: Text(
                                      _showTradingView
                                          ? 'Our Chart'
                                          : 'TradingView',
                                      style: TextStyle(fontSize: 10)),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                                Text(
                                  _isControlsVisible ? '' : 'Настройки скрыты',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    _isControlsVisible
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                    size: 16,
                                  ),
                                  padding: const EdgeInsets.all(2),
                                  constraints: const BoxConstraints(),
                                  tooltip: _isControlsVisible
                                      ? 'Скрыть настройки'
                                      : 'Показать настройки',
                                  onPressed: () {
                                    setState(() {
                                      _isControlsVisible = !_isControlsVisible;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          // Анимированная панель настроек
                          if (_isControlsVisible) ...[
                            // Chart style selector (Line vs Candle)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6.0, vertical: 2.0),
                              child: SegmentedButton<String>(
                                segments: const [
                                  ButtonSegment(
                                    value: 'line',
                                    label: Text('Линейный'),
                                    icon: Icon(Icons.show_chart, size: 14),
                                  ),
                                  ButtonSegment(
                                    value: 'candle',
                                    label: Text('Свечи'),
                                    icon:
                                        Icon(Icons.candlestick_chart, size: 14),
                                  ),
                                ],
                                selected: {_chartStyle},
                                onSelectionChanged: (Set<String> selected) {
                                  setState(() {
                                    _chartStyle = selected.first;
                                  });
                                },
                              ),
                            ),
                            // Chart type selector
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6.0, vertical: 1.0),
                              child: SegmentedButton<String>(
                                segments: isWide
                                    ? const [
                                        ButtonSegment(
                                          value: 'price',
                                          label: Text('Price',
                                              style: TextStyle(fontSize: 12)),
                                          icon:
                                              Icon(Icons.show_chart, size: 14),
                                        ),
                                        ButtonSegment(
                                          value: 'volume',
                                          label: Text('Volume',
                                              style: TextStyle(fontSize: 12)),
                                          icon: Icon(Icons.bar_chart, size: 14),
                                        ),
                                        ButtonSegment(
                                          value: 'marketcap',
                                          label: Text('Market Cap',
                                              style: TextStyle(fontSize: 12)),
                                          icon: Icon(Icons.pie_chart, size: 14),
                                        ),
                                      ]
                                    : const [
                                        ButtonSegment(
                                          value: 'price',
                                          label: Text('Price',
                                              style: TextStyle(fontSize: 11)),
                                          icon:
                                              Icon(Icons.show_chart, size: 12),
                                        ),
                                        ButtonSegment(
                                          value: 'volume',
                                          label: Text('Vol',
                                              style: TextStyle(fontSize: 11)),
                                          icon: Icon(Icons.bar_chart, size: 12),
                                        ),
                                        ButtonSegment(
                                          value: 'marketcap',
                                          label: Text('Cap',
                                              style: TextStyle(fontSize: 11)),
                                          icon: Icon(Icons.pie_chart, size: 12),
                                        ),
                                      ],
                                selected: {_chartType},
                                onSelectionChanged: (Set<String> selected) {
                                  setState(() {
                                    _chartType = selected.first;
                                  });
                                },
                              ),
                            ),
                            // Timeframe buttons
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6.0, vertical: 1.0),
                              child: Row(
                                mainAxisAlignment: isWide
                                    ? MainAxisAlignment.center
                                    : MainAxisAlignment.end,
                                children: [
                                  for (final d in [1, 7, 30])
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 2.0),
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: days == d
                                              ? Colors.blue
                                              : Colors.grey[300],
                                          foregroundColor: days == d
                                              ? Colors.white
                                              : Colors.black87,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 6),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        onPressed: () =>
                                            setState(() => days = d),
                                        child: Text('${d}d',
                                            style:
                                                const TextStyle(fontSize: 11)),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          // Chart
                          Expanded(
                            child: _showTradingView &&
                                    _webViewController != null
                                ? Stack(
                                    children: [
                                      WebViewWidget(
                                          controller: _webViewController!),
                                      Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ],
                                  )
                                : _showTradingView
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.web,
                                                size: 64,
                                                color: Colors.grey[400]),
                                            SizedBox(height: 16),
                                            Text(
                                              'TradingView не поддерживается в Web',
                                              style: TextStyle(fontSize: 16),
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Запустите приложение на Android эмуляторе',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[500]),
                                            ),
                                            SizedBox(height: 16),
                                            ElevatedButton(
                                              onPressed: () {
                                                setState(() {
                                                  _showTradingView = false;
                                                });
                                              },
                                              child:
                                                  Text('Вернуться к графику'),
                                            ),
                                          ],
                                        ),
                                      )
                                    : asyncPrices.when(
                                        data: (points) {
                                          if (points.isEmpty) {
                                            return const Center(
                                                child: Text('No data'));
                                          }

                                          // Если выбран свечной график и тип - цена
                                          if (_chartStyle == 'candle' &&
                                              _chartType == 'price') {
                                            // Получаем сырые данные для создания свечей
                                            return FutureBuilder<List<dynamic>>(
                                              future: CoinGeckoService
                                                  .fetchRawMarketChart(
                                                      id, 'usd', days),
                                              builder: (context, snapshot) {
                                                if (snapshot.connectionState ==
                                                    ConnectionState.waiting) {
                                                  return const Center(
                                                      child:
                                                          CircularProgressIndicator());
                                                }
                                                if (snapshot.hasError) {
                                                  return Center(
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        const Text(
                                                            'Failed to load chart data',
                                                            style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold)),
                                                        const SizedBox(
                                                            height: 8),
                                                        Text(
                                                            snapshot.error
                                                                .toString(),
                                                            style:
                                                                const TextStyle(
                                                                    fontSize:
                                                                        12)),
                                                        const SizedBox(
                                                            height: 8),
                                                        ElevatedButton(
                                                          onPressed: () {
                                                            setState(() {
                                                              // Trigger rebuild
                                                            });
                                                          },
                                                          child: const Text(
                                                              'Retry'),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }
                                                if (!snapshot.hasData ||
                                                    snapshot.data!.isEmpty) {
                                                  return const Center(
                                                      child: Text('No data'));
                                                }

                                                // Создаем свечи из сырых данных
                                                final candles =
                                                    CandleData.fromPricePoints(
                                                        snapshot.data!,
                                                        50 // количество свечей
                                                        );

                                                return CandlestickChart(
                                                    candles: candles);
                                              },
                                            );
                                          }

                                          // Иначе показываем линейный график
                                          return PriceChart(
                                            points: points,
                                            chartType: _chartType,
                                          );
                                        },
                                        loading: () => const Center(
                                            child: CircularProgressIndicator()),
                                        error: (e, st) => Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Text(
                                                  'Failed to load price data',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold)),
                                              const SizedBox(height: 8),
                                              Text(e.toString(),
                                                  style: const TextStyle(
                                                      fontSize: 12)),
                                              const SizedBox(height: 8),
                                              ElevatedButton(
                                                onPressed: () => ref.refresh(
                                                    pricesFutureProvider(
                                                        '$id|$days')),
                                                child: const Text('Retry'),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                          ),
                        ],
                      ),
                    ),

                    // Sliding info panel
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      left: _isPanelOpen ? 0 : (isWide ? -400 : -320),
                      top: 0,
                      bottom: 0,
                      width: isWide ? 400 : 320,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF25253B),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black38,
                                blurRadius: 10,
                                offset: Offset(2, 0)),
                          ],
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(mi.name,
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white)),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                        color: const Color(0xFF2C2C3E),
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    child: Text(mi.symbol,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.white70)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                NumberFormat.simpleCurrency()
                                    .format(mi.currentPrice),
                                style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                mi.priceChange24h != null
                                    ? '${mi.priceChange24h!.toStringAsFixed(2)}%'
                                    : '-',
                                style: TextStyle(
                                    fontSize: 16,
                                    color: (mi.priceChange24h ?? 0) >= 0
                                        ? Colors.green
                                        : Colors.red),
                              ),
                              const SizedBox(height: 16),
                              if (mi.low24h != null && mi.high24h != null) ...[
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(NumberFormat.simpleCurrency()
                                        .format(mi.low24h)),
                                    Text('24h Range',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[500])),
                                    Text(NumberFormat.simpleCurrency()
                                        .format(mi.high24h)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                LayoutBuilder(builder: (context, constraints) {
                                  final low = mi.low24h!;
                                  final high = mi.high24h!;
                                  final pos =
                                      ((mi.currentPrice - low) / (high - low))
                                          .clamp(0.0, 1.0);
                                  return Stack(
                                    children: [
                                      Container(
                                        height: 8,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                            color: const Color(0xFF2C2C3E),
                                            borderRadius:
                                                BorderRadius.circular(4)),
                                      ),
                                      Container(
                                        height: 8,
                                        width: constraints.maxWidth * pos,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                              colors: [
                                                Colors.yellow,
                                                Colors.green
                                              ]),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                                const SizedBox(height: 12),
                              ],
                              Text('Market stats',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.white)),
                              const SizedBox(height: 8),
                              if (mi.rank != null)
                                _statRow('Rank', '#${mi.rank}'),
                              _statRow(
                                  'Market Cap',
                                  mi.marketCap != null
                                      ? '\$' +
                                          NumberFormat.compact()
                                              .format(mi.marketCap)
                                      : '—'),
                              _statRow(
                                  '24h Volume',
                                  mi.volume24h != null
                                      ? '\$' +
                                          NumberFormat.compact()
                                              .format(mi.volume24h)
                                      : '—'),
                              _statRow(
                                  'Circulating Supply',
                                  mi.circulatingSupply != null
                                      ? NumberFormat.compact()
                                          .format(mi.circulatingSupply)
                                      : '—'),
                              _statRow(
                                  'Total Supply',
                                  mi.totalSupply != null
                                      ? NumberFormat.compact()
                                          .format(mi.totalSupply)
                                      : '—'),
                              _statRow(
                                  'Max Supply',
                                  mi.maxSupply != null
                                      ? NumberFormat.compact()
                                          .format(mi.maxSupply)
                                      : '—'),
                              const SizedBox(height: 12),
                              Text(
                                  'Информационный просмотр — торговые операции не поддерживаются.',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey[500])),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Toggle button
                    Positioned(
                      left: _isPanelOpen ? (isWide ? 400 : 320) : 0,
                      top: 60,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isPanelOpen = !_isPanelOpen;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 40,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C2C3E),
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black38,
                                  blurRadius: 6,
                                  offset: Offset(2, 0)),
                            ],
                          ),
                          child: Icon(
                            _isPanelOpen
                                ? Icons.chevron_left
                                : Icons.chevron_right,
                            color: const Color(0xFF0052FF),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Failed to load market info: $e')),
      ),
      bottomNavigationBar: marketAsync.when(
        data: (markets) {
          final mi = markets.firstWhere(
            (m) => m.id == id,
            orElse: () =>
                MarketInfo(id: id, name: name, symbol: '', currentPrice: 0.0),
          );

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: const Color(0xFF25253B),
              boxShadow: [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showTradeDialog(
                        context, id, name, mi.symbol, mi.currentPrice, true),
                    icon: const Icon(Icons.arrow_downward, size: 14),
                    label: const Text('КУПИТЬ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16C784),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 6),
                      textStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showTradeDialog(
                        context, id, name, mi.symbol, mi.currentPrice, false),
                    icon: const Icon(Icons.arrow_upward, size: 14),
                    label: const Text('ПРОДАТЬ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEA3943),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 6),
                      textStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (e, st) => const SizedBox.shrink(),
      ),
    );
  }

  void _showTradeDialog(BuildContext context, String coinId, String coinName,
      String coinSymbol, double currentPrice, bool isBuy) {
    final amountController = TextEditingController();
    final totalController = TextEditingController();

    void updateTotal() {
      final amount = double.tryParse(amountController.text) ?? 0.0;
      totalController.text = (amount * currentPrice).toStringAsFixed(2);
    }

    void updateAmount() {
      final total = double.tryParse(totalController.text) ?? 0.0;
      amountController.text = (total / currentPrice).toStringAsFixed(8);
    }

    showDialog(
      context: context,
      builder: (dialogContext) => Consumer(
        builder: (context, ref, child) {
          final portfolioAsync = ref.watch(portfolioProvider);

          return AlertDialog(
            title: Text(isBuy ? 'Купить $coinName' : 'Продать $coinName'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  portfolioAsync.when(
                    data: (portfolio) {
                      final position = ref
                          .read(portfolioProvider.notifier)
                          .getPosition(coinId);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Баланс: ${NumberFormat.simpleCurrency().format(portfolio.balance)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (position != null)
                            Text(
                              'В портфеле: ${position.amount.toStringAsFixed(8)} $coinSymbol',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                        ],
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (e, st) => Text('Ошибка: $e'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Текущая цена: ${NumberFormat.simpleCurrency().format(currentPrice)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Количество $coinSymbol',
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) => updateTotal(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: totalController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Всего USD',
                      prefixText: '\$',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => updateAmount(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(amountController.text);
                  if (amount == null || amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Введите корректное количество')),
                    );
                    return;
                  }

                  try {
                    final notifier = ref.read(portfolioProvider.notifier);

                    if (isBuy) {
                      await notifier.buy(
                        coinId: coinId,
                        coinName: coinName,
                        coinSymbol: coinSymbol,
                        price: currentPrice,
                        amount: amount,
                      );
                    } else {
                      await notifier.sell(
                        coinId: coinId,
                        coinName: coinName,
                        coinSymbol: coinSymbol,
                        price: currentPrice,
                        amount: amount,
                      );
                    }

                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isBuy
                              ? 'Куплено: ${amount.toStringAsFixed(8)} $coinSymbol'
                              : 'Продано: ${amount.toStringAsFixed(8)} $coinSymbol',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString()),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isBuy ? Colors.green : Colors.red,
                ),
                child: Text(isBuy ? 'Купить' : 'Продать'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAlertsDialog(BuildContext context, String coinId, String coinName) {
    final coinAlertsAsync = ref.read(coinAlertsProvider(coinId));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Price Alerts for $coinName'),
        content: SizedBox(
          width: double.maxFinite,
          child: coinAlertsAsync.when(
            data: (alerts) {
              if (alerts.isEmpty) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications_off,
                        size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text('No price alerts set',
                        style: TextStyle(color: Colors.grey[600])),
                  ],
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                itemCount: alerts.length,
                itemBuilder: (context, index) {
                  final alert = alerts[index];
                  return ListTile(
                    leading: Icon(
                      alert.isAbove ? Icons.trending_up : Icons.trending_down,
                      color: alert.isAbove ? Colors.green : Colors.red,
                    ),
                    title: Text(
                      '${alert.isAbove ? 'Above' : 'Below'} \$${alert.targetPrice.toStringAsFixed(2)}',
                    ),
                    subtitle: Text('Created ${_formatDate(alert.createdAt)}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final service = ref.read(priceAlertsServiceProvider);
                        await service.removeAlert(alert.id);
                        ref.invalidate(coinAlertsProvider(coinId));
                        ref.invalidate(priceAlertsProvider);
                      },
                    ),
                  );
                },
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (e, st) => Text('Error: $e'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showCreateAlertDialog(context, coinId, coinName);
            },
            icon: const Icon(Icons.add),
            label: const Text('New Alert'),
          ),
        ],
      ),
    );
  }

  void _showCreateAlertDialog(
      BuildContext context, String coinId, String coinName) {
    final controller = TextEditingController();
    bool isAbove = true;

    // Get current price
    final marketAsync = ref.read(marketProvider);
    double? currentPrice;
    marketAsync.whenData((markets) {
      final mi = markets.firstWhere((m) => m.id == coinId,
          orElse: () => MarketInfo(
              id: coinId, name: coinName, symbol: '', currentPrice: 0.0));
      currentPrice = mi.currentPrice;
      controller.text = mi.currentPrice.toStringAsFixed(2);
    });

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Price Alert'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (currentPrice != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      'Current price: \$${currentPrice!.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Target Price',
                    prefixText: '\$',
                    border: OutlineInputBorder(),
                    helperText: 'Enter the price to trigger alert',
                  ),
                ),
                const SizedBox(height: 16),
                Text('Alert when price goes:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Radio<bool>(
                            value: true,
                            groupValue: isAbove,
                            onChanged: (value) {
                              setState(() => isAbove = value!);
                            },
                          ),
                          const Icon(Icons.trending_up,
                              color: Colors.green, size: 20),
                          const SizedBox(width: 4),
                          const Text('Above', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Radio<bool>(
                            value: false,
                            groupValue: isAbove,
                            onChanged: (value) {
                              setState(() => isAbove = value!);
                            },
                          ),
                          const Icon(Icons.trending_down,
                              color: Colors.red, size: 20),
                          const SizedBox(width: 4),
                          const Text('Below', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final targetPrice = double.tryParse(controller.text);
                if (targetPrice == null || targetPrice <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid price')),
                  );
                  return;
                }

                // Request notification permissions
                await NotificationService().requestPermissions();

                // Create alert
                final alert = PriceAlert(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  coinId: coinId,
                  coinName: coinName,
                  targetPrice: targetPrice,
                  isAbove: isAbove,
                  createdAt: DateTime.now(),
                );

                final service = ref.read(priceAlertsServiceProvider);
                await service.addAlert(alert);

                // Refresh providers
                ref.invalidate(coinAlertsProvider(coinId));
                ref.invalidate(priceAlertsProvider);

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Alert created: ${isAbove ? 'Above' : 'Below'} \$${targetPrice.toStringAsFixed(2)}'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }
}

Widget _statRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.white)),
      ],
    ),
  );
}
