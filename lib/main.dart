import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/coin_list.dart';
import 'screens/coin_detail.dart';
import 'screens/favorites_screen.dart';
import 'screens/price_alerts_screen.dart';
import 'screens/coin_comparison_screen.dart';
import 'services/notification_service.dart';
import 'services/price_monitor_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notification service
  await NotificationService().initialize();

  // Start price monitoring
  PriceMonitorService().startMonitoring();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crypto Chart',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        if (settings.name == '/') {
          return MaterialPageRoute(builder: (_) => const CoinListScreen());
        }
        if (settings.name == '/favorites') {
          return MaterialPageRoute(builder: (_) => const FavoritesScreen());
        }
        if (settings.name == '/alerts') {
          return MaterialPageRoute(builder: (_) => const PriceAlertsScreen());
        }
        if (settings.name == '/comparison') {
          return MaterialPageRoute(
              builder: (_) => const CoinComparisonScreen());
        }
        if (settings.name == '/detail') {
          return MaterialPageRoute(
              builder: (_) => const CoinDetailScreen(), settings: settings);
        }
        return null;
      },
    );
  }
}
