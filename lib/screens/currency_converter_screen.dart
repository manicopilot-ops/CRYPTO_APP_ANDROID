import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/coin_provider.dart';

class CurrencyConverterScreen extends ConsumerStatefulWidget {
  const CurrencyConverterScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CurrencyConverterScreen> createState() =>
      _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState
    extends ConsumerState<CurrencyConverterScreen> {
  final _fromController = TextEditingController(text: '1');
  final _toController = TextEditingController();

  String _fromCurrency = 'bitcoin';
  String _toCurrency = 'usd';

  final _fiatCurrencies = {
    'usd': {'name': 'US Dollar', 'symbol': '\$'},
    'eur': {'name': 'Euro', 'symbol': '€'},
    'rub': {'name': 'Russian Ruble', 'symbol': '₽'},
  };

  @override
  void initState() {
    super.initState();
    _fromController.addListener(_convert);
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  void _convert() {
    final amount = double.tryParse(_fromController.text);
    if (amount == null || amount == 0) {
      _toController.text = '';
      return;
    }

    final marketsAsync = ref.read(marketProvider);
    marketsAsync.whenData((markets) {
      if (markets.isEmpty) return;

      double rate = 1.0;
      bool fromIsFiat = _fiatCurrencies.containsKey(_fromCurrency);
      bool toIsFiat = _fiatCurrencies.containsKey(_toCurrency);

      if (fromIsFiat && toIsFiat) {
        // Fiat to Fiat - not supported, just return 1:1
        rate = 1.0;
      } else if (!fromIsFiat && toIsFiat) {
        // Crypto to Fiat
        try {
          final coin = markets.firstWhere((m) => m.id == _fromCurrency);
          rate = coin.currentPrice;
        } catch (e) {
          _toController.text = '0';
          return;
        }
      } else if (fromIsFiat && !toIsFiat) {
        // Fiat to Crypto
        try {
          final coin = markets.firstWhere((m) => m.id == _toCurrency);
          rate = 1.0 / coin.currentPrice;
        } catch (e) {
          _toController.text = '0';
          return;
        }
      } else {
        // Crypto to Crypto
        try {
          final fromCoin = markets.firstWhere((m) => m.id == _fromCurrency);
          final toCoin = markets.firstWhere((m) => m.id == _toCurrency);
          rate = fromCoin.currentPrice / toCoin.currentPrice;
        } catch (e) {
          _toController.text = '0';
          return;
        }
      }

      final result = amount * rate;
      _toController.text = result.toStringAsFixed(8);
    });
  }

  void _swap() {
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;

      final tempText = _fromController.text;
      _fromController.text = _toController.text;
      _toController.text = tempText;
    });
  }

  @override
  Widget build(BuildContext context) {
    final coins = ref.watch(coinListProvider);
    final marketsAsync = ref.watch(marketProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Currency Converter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_vert),
            onPressed: _swap,
            tooltip: 'Swap currencies',
          ),
        ],
      ),
      body: marketsAsync.when(
        data: (markets) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info card
                Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.currency_exchange,
                            color: Colors.blue[700], size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Convert between cryptocurrencies and fiat currencies using real-time rates',
                            style: TextStyle(color: Colors.blue[900]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // FROM section
                _buildCurrencySection(
                  controller: _fromController,
                  label: 'From',
                  selectedCurrency: _fromCurrency,
                  coins: coins,
                  markets: markets,
                  onCurrencyChanged: (value) {
                    setState(() => _fromCurrency = value!);
                    _convert();
                  },
                ),
                const SizedBox(height: 16),

                // Swap button
                Center(
                  child: IconButton.filled(
                    icon: const Icon(Icons.swap_vert, size: 32),
                    onPressed: _swap,
                    iconSize: 48,
                  ),
                ),
                const SizedBox(height: 16),

                // TO section
                _buildCurrencySection(
                  controller: _toController,
                  label: 'To',
                  selectedCurrency: _toCurrency,
                  coins: coins,
                  markets: markets,
                  onCurrencyChanged: (value) {
                    setState(() => _toCurrency = value!);
                    _convert();
                  },
                  readOnly: true,
                ),
                const SizedBox(height: 32),

                // Exchange rate info
                _buildExchangeRateCard(markets),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading rates: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(marketProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencySection({
    required TextEditingController controller,
    required String label,
    required String selectedCurrency,
    required List<Map<String, String>> coins,
    required List markets,
    required void Function(String?) onCurrencyChanged,
    bool readOnly = false,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Currency selector
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: selectedCurrency,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      // Fiat currencies
                      ..._fiatCurrencies.entries.map((entry) {
                        return DropdownMenuItem(
                          value: entry.key,
                          child: Row(
                            children: [
                              Text(entry.value['symbol']!,
                                  style: const TextStyle(fontSize: 18)),
                              const SizedBox(width: 8),
                              Text(entry.key.toUpperCase()),
                            ],
                          ),
                        );
                      }),
                      // Crypto currencies
                      ...coins.take(50).map((coin) {
                        return DropdownMenuItem(
                          value: coin['id']!,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 10,
                                child: Text(
                                  coin['symbol']!.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  coin['name']!,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                    onChanged: onCurrencyChanged,
                  ),
                ),
                const SizedBox(width: 12),
                // Amount input
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: controller,
                    readOnly: readOnly,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: '0.00',
                      filled: readOnly,
                      fillColor: readOnly ? Colors.grey[100] : null,
                    ),
                  ),
                ),
              ],
            ),
            if (!readOnly && !_fiatCurrencies.containsKey(selectedCurrency))
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: _buildCurrentPrice(selectedCurrency, markets),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPrice(String coinId, List markets) {
    try {
      final coin = markets.firstWhere((m) => m.id == coinId);
      final fmt = NumberFormat.simpleCurrency();
      return Text(
        '≈ ${fmt.format(coin.currentPrice)}',
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  Widget _buildExchangeRateCard(List markets) {
    if (_fiatCurrencies.containsKey(_fromCurrency) &&
        _fiatCurrencies.containsKey(_toCurrency)) {
      return const SizedBox.shrink();
    }

    if (markets.isEmpty) return const SizedBox.shrink();

    double rate = 1.0;
    String rateText = '';

    try {
      if (!_fiatCurrencies.containsKey(_fromCurrency)) {
        final coin = markets.firstWhere(
          (m) => m.id == _fromCurrency,
        );
        rate = coin.currentPrice;
        rateText =
            '1 ${coin.symbol.toUpperCase()} = ${NumberFormat.simpleCurrency().format(rate)}';
      }

      if (!_fiatCurrencies.containsKey(_toCurrency)) {
        final coin = markets.firstWhere(
          (m) => m.id == _toCurrency,
        );
        if (!_fiatCurrencies.containsKey(_fromCurrency)) {
          final fromCoin = markets.firstWhere(
            (m) => m.id == _fromCurrency,
          );
          rate = fromCoin.currentPrice / coin.currentPrice;
          rateText =
              '1 ${fromCoin.symbol.toUpperCase()} = ${rate.toStringAsFixed(8)} ${coin.symbol.toUpperCase()}';
        } else {
          rate = 1.0 / coin.currentPrice;
          rateText =
              '1 ${coin.symbol.toUpperCase()} = ${NumberFormat.simpleCurrency().format(coin.currentPrice)}';
        }
      }
    } catch (e) {
      return const SizedBox.shrink();
    }

    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.green[700]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Exchange Rate',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rateText,
                    style: TextStyle(color: Colors.green[900], fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
