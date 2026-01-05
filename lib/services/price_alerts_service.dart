import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/price_alert.dart';

class PriceAlertsService {
  static const String _alertsKey = 'price_alerts';

  Future<List<PriceAlert>> getAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final alertsJson = prefs.getStringList(_alertsKey) ?? [];

    return alertsJson
        .map((json) => PriceAlert.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<List<PriceAlert>> getAlertsForCoin(String coinId) async {
    final alerts = await getAlerts();
    return alerts.where((a) => a.coinId == coinId && a.isActive).toList();
  }

  Future<void> addAlert(PriceAlert alert) async {
    final prefs = await SharedPreferences.getInstance();
    final alerts = await getAlerts();
    alerts.add(alert);

    final alertsJson =
        alerts.map((alert) => jsonEncode(alert.toJson())).toList();
    await prefs.setStringList(_alertsKey, alertsJson);
  }

  Future<void> removeAlert(String alertId) async {
    final prefs = await SharedPreferences.getInstance();
    final alerts = await getAlerts();
    alerts.removeWhere((a) => a.id == alertId);

    final alertsJson =
        alerts.map((alert) => jsonEncode(alert.toJson())).toList();
    await prefs.setStringList(_alertsKey, alertsJson);
  }

  Future<void> deactivateAlert(String alertId) async {
    final prefs = await SharedPreferences.getInstance();
    final alerts = await getAlerts();
    final index = alerts.indexWhere((a) => a.id == alertId);

    if (index != -1) {
      alerts[index] = PriceAlert(
        id: alerts[index].id,
        coinId: alerts[index].coinId,
        coinName: alerts[index].coinName,
        targetPrice: alerts[index].targetPrice,
        isAbove: alerts[index].isAbove,
        createdAt: alerts[index].createdAt,
        isActive: false,
      );

      final alertsJson =
          alerts.map((alert) => jsonEncode(alert.toJson())).toList();
      await prefs.setStringList(_alertsKey, alertsJson);
    }
  }

  Future<void> clearAllAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_alertsKey);
  }
}
