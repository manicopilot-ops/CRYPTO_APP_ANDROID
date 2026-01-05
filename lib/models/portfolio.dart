class Trade {
  final String id;
  final String coinId;
  final String coinName;
  final String coinSymbol;
  final TradeType type; // buy или sell
  final double price;
  final double amount;
  final double total;
  final DateTime timestamp;

  Trade({
    required this.id,
    required this.coinId,
    required this.coinName,
    required this.coinSymbol,
    required this.type,
    required this.price,
    required this.amount,
    required this.total,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'coinId': coinId,
        'coinName': coinName,
        'coinSymbol': coinSymbol,
        'type': type.name,
        'price': price,
        'amount': amount,
        'total': total,
        'timestamp': timestamp.toIso8601String(),
      };

  factory Trade.fromJson(Map<String, dynamic> json) => Trade(
        id: json['id'] as String,
        coinId: json['coinId'] as String,
        coinName: json['coinName'] as String,
        coinSymbol: json['coinSymbol'] as String,
        type: TradeType.values.firstWhere((e) => e.name == json['type']),
        price: (json['price'] as num).toDouble(),
        amount: (json['amount'] as num).toDouble(),
        total: (json['total'] as num).toDouble(),
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

enum TradeType { buy, sell }

class Position {
  final String coinId;
  final String coinName;
  final String coinSymbol;
  final double amount;
  final double averagePrice;

  Position({
    required this.coinId,
    required this.coinName,
    required this.coinSymbol,
    required this.amount,
    required this.averagePrice,
  });

  double get totalValue => amount * averagePrice;

  Map<String, dynamic> toJson() => {
        'coinId': coinId,
        'coinName': coinName,
        'coinSymbol': coinSymbol,
        'amount': amount,
        'averagePrice': averagePrice,
      };

  factory Position.fromJson(Map<String, dynamic> json) => Position(
        coinId: json['coinId'] as String,
        coinName: json['coinName'] as String,
        coinSymbol: json['coinSymbol'] as String,
        amount: (json['amount'] as num).toDouble(),
        averagePrice: (json['averagePrice'] as num).toDouble(),
      );

  Position copyWith({
    String? coinId,
    String? coinName,
    String? coinSymbol,
    double? amount,
    double? averagePrice,
  }) {
    return Position(
      coinId: coinId ?? this.coinId,
      coinName: coinName ?? this.coinName,
      coinSymbol: coinSymbol ?? this.coinSymbol,
      amount: amount ?? this.amount,
      averagePrice: averagePrice ?? this.averagePrice,
    );
  }
}

class Portfolio {
  final double balance;
  final List<Position> positions;
  final List<Trade> tradeHistory;

  Portfolio({
    required this.balance,
    required this.positions,
    required this.tradeHistory,
  });

  double get totalValue {
    final positionsValue = positions.fold<double>(
      0.0,
      (sum, pos) => sum + pos.totalValue,
    );
    return balance + positionsValue;
  }

  Map<String, dynamic> toJson() => {
        'balance': balance,
        'positions': positions.map((p) => p.toJson()).toList(),
        'tradeHistory': tradeHistory.map((t) => t.toJson()).toList(),
      };

  factory Portfolio.fromJson(Map<String, dynamic> json) => Portfolio(
        balance: (json['balance'] as num).toDouble(),
        positions: (json['positions'] as List)
            .map((p) => Position.fromJson(p as Map<String, dynamic>))
            .toList(),
        tradeHistory: (json['tradeHistory'] as List)
            .map((t) => Trade.fromJson(t as Map<String, dynamic>))
            .toList(),
      );

  Portfolio copyWith({
    double? balance,
    List<Position>? positions,
    List<Trade>? tradeHistory,
  }) {
    return Portfolio(
      balance: balance ?? this.balance,
      positions: positions ?? this.positions,
      tradeHistory: tradeHistory ?? this.tradeHistory,
    );
  }

  static Portfolio initial() => Portfolio(
        balance: 10000.0, // Начальный виртуальный баланс $10,000
        positions: [],
        tradeHistory: [],
      );
}
