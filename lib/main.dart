import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/coin_list.dart';
import 'screens/coin_detail.dart';

void main() {
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
        if (settings.name == '/detail') {
          return MaterialPageRoute(
              builder: (_) => const CoinDetailScreen(), settings: settings);
        }
        return null;
      },
    );
  }
}
