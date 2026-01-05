import 'dart:async';
import '../services/coingecko_service.dart';
import '../services/price_alerts_service.dart';
import '../services/notification_service.dart';

class PriceMonitorService {
  static final PriceMonitorService _instance = PriceMonitorService._internal();
  factory PriceMonitorService() => _instance;
  PriceMonitorService._internal();

  Timer? _timer;
  final _alertsService = PriceAlertsService();
  final _notificationService = NotificationService();

  bool get isMonitoring => _timer != null && _timer!.isActive;

  // Start monitoring prices every 5 minutes
  void startMonitoring() {
    if (isMonitoring) return;

    print('Starting price monitoring...');
    _timer = Timer.periodic(const Duration(minutes: 5), (_) {
      _checkAlerts();
    });

    // Check immediately on start
    _checkAlerts();
  }

  void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
    print('Stopped price monitoring');
  }

  Future<void> _checkAlerts() async {
    try {
      final alerts = await _alertsService.getAlerts();
      if (alerts.isEmpty) return;

      // Get unique coin IDs
      final coinIds = alerts.map((a) => a.coinId).toSet().toList();

      // Fetch current prices
      final markets = await CoinGeckoService.fetchMarkets(coinIds);
      final priceMap = {for (var m in markets) m.id: m.currentPrice};

      // Check each alert
      for (final alert in alerts) {
        if (!alert.isActive) continue;

        final currentPrice = priceMap[alert.coinId];
        if (currentPrice == null) continue;

        bool shouldTrigger = false;
        if (alert.isAbove && currentPrice >= alert.targetPrice) {
          shouldTrigger = true;
        } else if (!alert.isAbove && currentPrice <= alert.targetPrice) {
          shouldTrigger = true;
        }

        if (shouldTrigger) {
          print('Alert triggered: ${alert.coinName} - \$${currentPrice}');

          // Show notification
          await _notificationService.showPriceAlert(
            coinName: alert.coinName,
            currentPrice: currentPrice,
            targetPrice: alert.targetPrice,
            isAbove: alert.isAbove,
          );

          // Deactivate the alert so it doesn't trigger again
          await _alertsService.deactivateAlert(alert.id);
        }
      }
    } catch (e) {
      print('Error checking alerts: $e');
    }
  }

  // Manual check for testing
  Future<void> checkAlertsNow() async {
    print('Manually checking alerts...');
    await _checkAlerts();
  }
}
