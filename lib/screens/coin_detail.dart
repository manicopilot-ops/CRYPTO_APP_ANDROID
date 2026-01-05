import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/market_info.dart';
import '../models/price_alert.dart';
import '../providers/coin_provider.dart';
import '../providers/price_alerts_provider.dart';
import '../services/notification_service.dart';
import '../widgets/price_chart.dart';

class CoinDetailScreen extends ConsumerStatefulWidget {
  const CoinDetailScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CoinDetailScreen> createState() => _CoinDetailScreenState();
}

class _CoinDetailScreenState extends ConsumerState<CoinDetailScreen> {
  int days = 7;
  bool _isPanelOpen = false;
  String _chartType = 'price'; // 'price', 'volume', 'marketcap'

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
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(name),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Price Alerts',
            onPressed: () => _showAlertsDialog(context, id, name),
          ),
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
            padding: const EdgeInsets.all(16.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 700;
                final fmt = NumberFormat.simpleCurrency();
                final cmpFmt = NumberFormat.compact();

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left info panel
                      Container(
                        width: 360,
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.0),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: Offset(0, 2)),
                          ],
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(mi.name,
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    child: Text(mi.symbol,
                                        style: const TextStyle(fontSize: 12)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                NumberFormat.simpleCurrency()
                                    .format(mi.currentPrice),
                                style: const TextStyle(
                                    fontSize: 32, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                mi.priceChange24h != null
                                    ? '${mi.priceChange24h!.toStringAsFixed(2)}%'
                                    : '-',
                                style: TextStyle(
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
                                    const Text('24h Range',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54)),
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
                                            color: Colors.grey[200],
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
                              const Text('Market stats',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
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
                              const Text(
                                  'Информационный просмотр — торговые операции не поддерживаются.',
                                  style: TextStyle(color: Colors.black54)),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Right panel: chart + controls
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Chart type and timeframe buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Chart type selector
                                SegmentedButton<String>(
                                  segments: const [
                                    ButtonSegment(
                                      value: 'price',
                                      label: Text('Price'),
                                      icon: Icon(Icons.show_chart, size: 16),
                                    ),
                                    ButtonSegment(
                                      value: 'volume',
                                      label: Text('Volume'),
                                      icon: Icon(Icons.bar_chart, size: 16),
                                    ),
                                    ButtonSegment(
                                      value: 'marketcap',
                                      label: Text('Market Cap'),
                                      icon: Icon(Icons.pie_chart, size: 16),
                                    ),
                                  ],
                                  selected: {_chartType},
                                  onSelectionChanged: (Set<String> selected) {
                                    setState(() {
                                      _chartType = selected.first;
                                    });
                                  },
                                ),
                                // Timeframe buttons
                                Row(
                                  children: [
                                    for (final d in [1, 7, 30])
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4.0),
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: days == d
                                                ? Colors.blue
                                                : Colors.grey[300],
                                            foregroundColor: days == d
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                          onPressed: () =>
                                              setState(() => days = d),
                                          child: Text('${d}d'),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // chart area
                            Expanded(
                              child: asyncPrices.when(
                                data: (points) => points.isEmpty
                                    ? const Center(child: Text('No data'))
                                    : PriceChart(
                                        points: points,
                                        chartType: _chartType,
                                      ),
                                loading: () => const Center(
                                    child: CircularProgressIndicator()),
                                error: (e, st) => SingleChildScrollView(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('Failed to load price data',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      Text(e.toString()),
                                      const SizedBox(height: 8),
                                      Text(st.toString(),
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey)),
                                      const SizedBox(height: 12),
                                      ElevatedButton(
                                        onPressed: () => ref.refresh(
                                            pricesFutureProvider('$id|$days')),
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
                    ],
                  );
                } else {
                  // Mobile layout: sliding panel over chart
                  return Stack(
                    children: [
                      // Chart area (full screen)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Chart type selector
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(
                                  value: 'price',
                                  label: Text('Price'),
                                  icon: Icon(Icons.show_chart, size: 14),
                                ),
                                ButtonSegment(
                                  value: 'volume',
                                  label: Text('Vol'),
                                  icon: Icon(Icons.bar_chart, size: 14),
                                ),
                                ButtonSegment(
                                  value: 'marketcap',
                                  label: Text('Cap'),
                                  icon: Icon(Icons.pie_chart, size: 14),
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              for (final d in [1, 7, 30])
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4.0),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: days == d
                                          ? Colors.blue
                                          : Colors.grey[300],
                                      foregroundColor: days == d
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                    onPressed: () => setState(() => days = d),
                                    child: Text('${d}d'),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Chart
                          Expanded(
                            child: asyncPrices.when(
                              data: (points) => points.isEmpty
                                  ? const Center(child: Text('No data'))
                                  : PriceChart(
                                      points: points,
                                      chartType: _chartType,
                                    ),
                              loading: () => const Center(
                                  child: CircularProgressIndicator()),
                              error: (e, st) => Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('Failed to load price data',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    Text(e.toString(),
                                        style: const TextStyle(fontSize: 12)),
                                    const SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: () => ref.refresh(
                                          pricesFutureProvider('$id|$days')),
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Sliding info panel
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        left: _isPanelOpen ? 0 : -320,
                        top: 0,
                        bottom: 0,
                        width: 320,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black26,
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
                                              fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      child: Text(mi.symbol,
                                          style: const TextStyle(fontSize: 12)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  fmt.format(mi.currentPrice),
                                  style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold),
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
                                if (mi.low24h != null &&
                                    mi.high24h != null) ...[
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(fmt.format(mi.low24h),
                                          style: const TextStyle(fontSize: 12)),
                                      const Text('24h Range',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.black54)),
                                      Text(fmt.format(mi.high24h),
                                          style: const TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  LayoutBuilder(
                                      builder: (context, constraints) {
                                    final low = mi.low24h!;
                                    final high = mi.high24h!;
                                    final pos =
                                        ((mi.currentPrice - low) / (high - low))
                                            .clamp(0.0, 1.0);
                                    return Stack(
                                      children: [
                                        Container(
                                          height: 6,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              borderRadius:
                                                  BorderRadius.circular(3)),
                                        ),
                                        Container(
                                          height: 6,
                                          width: constraints.maxWidth * pos,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                                colors: [
                                                  Colors.yellow,
                                                  Colors.green
                                                ]),
                                            borderRadius:
                                                BorderRadius.circular(3),
                                          ),
                                        ),
                                      ],
                                    );
                                  }),
                                  const SizedBox(height: 12),
                                ],
                                const Text('Market stats',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                _statRow(
                                    'Market Cap',
                                    mi.marketCap != null
                                        ? '\$${cmpFmt.format(mi.marketCap)}'
                                        : '—'),
                                _statRow(
                                    '24h Volume',
                                    mi.volume24h != null
                                        ? '\$${cmpFmt.format(mi.volume24h)}'
                                        : '—'),
                                _statRow(
                                    'Circulating',
                                    mi.circulatingSupply != null
                                        ? cmpFmt.format(mi.circulatingSupply)
                                        : '—'),
                                _statRow(
                                    'Total Supply',
                                    mi.totalSupply != null
                                        ? cmpFmt.format(mi.totalSupply)
                                        : '—'),
                                _statRow(
                                    'Max Supply',
                                    mi.maxSupply != null
                                        ? cmpFmt.format(mi.maxSupply)
                                        : '—'),
                                const SizedBox(height: 12),
                                const Text(
                                    'Информационный просмотр — торговые операции не поддерживаются.',
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.black54)),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Toggle button
                      Positioned(
                        left: _isPanelOpen ? 320 : 0,
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
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(8),
                                bottomRight: Radius.circular(8),
                              ),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 6,
                                    offset: Offset(2, 0)),
                              ],
                            ),
                            child: Icon(
                              _isPanelOpen
                                  ? Icons.chevron_left
                                  : Icons.chevron_right,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Failed to load market info: $e')),
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
          title: Text('Create Price Alert'),
          content: Column(
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
                    child: RadioListTile<bool>(
                      title: Row(
                        children: const [
                          Icon(Icons.trending_up, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Above'),
                        ],
                      ),
                      value: true,
                      groupValue: isAbove,
                      onChanged: (value) {
                        setState(() => isAbove = value!);
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: Row(
                        children: const [
                          Icon(Icons.trending_down, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Below'),
                        ],
                      ),
                      value: false,
                      groupValue: isAbove,
                      onChanged: (value) {
                        setState(() => isAbove = value!);
                      },
                    ),
                  ),
                ],
              ),
            ],
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
    padding: const EdgeInsets.symmetric(vertical: 6.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );
}
