import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/main_navigation.dart';
import 'screens/coin_detail.dart';
import 'screens/demo_trading_screen.dart';
import 'screens/price_alerts_screen.dart';
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
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF0052FF),
        scaffoldBackgroundColor: const Color(0xFF1C1C28),
        cardColor: const Color(0xFF25253B),
        dividerColor: const Color(0xFF3B3B54),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF25253B),
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0052FF),
            foregroundColor: Colors.white,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF0052FF),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2C2C3E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          hintStyle: TextStyle(color: Colors.grey[500]),
        ),
        popupMenuTheme: const PopupMenuThemeData(
          color: Color(0xFF25253B),
        ),
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        if (settings.name == '/') {
          return MaterialPageRoute(builder: (_) => const MainNavigation());
        }
        if (settings.name == '/demo-trading') {
          return MaterialPageRoute(builder: (_) => const DemoTradingScreen());
        }
        if (settings.name == '/alerts') {
          return MaterialPageRoute(builder: (_) => const PriceAlertsScreen());
        }
        if (settings.name == '/coin-detail') {
          return MaterialPageRoute(
              builder: (_) => const CoinDetailScreen(), settings: settings);
        }
        return null;
      },
    );
  }
}
