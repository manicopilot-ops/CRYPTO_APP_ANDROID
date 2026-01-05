import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/price_alert.dart';
import '../services/price_alerts_service.dart';

final priceAlertsServiceProvider = Provider<PriceAlertsService>((ref) {
  return PriceAlertsService();
});

final priceAlertsProvider = FutureProvider<List<PriceAlert>>((ref) async {
  final service = ref.read(priceAlertsServiceProvider);
  return service.getAlerts();
});

final coinAlertsProvider =
    FutureProvider.family<List<PriceAlert>, String>((ref, coinId) async {
  final service = ref.read(priceAlertsServiceProvider);
  return service.getAlertsForCoin(coinId);
});
