class PriceAlert {
  final String id;
  final String coinId;
  final String coinName;
  final double targetPrice;
  final bool isAbove; // true = alert when price goes above, false = below
  final DateTime createdAt;
  final bool isActive;

  PriceAlert({
    required this.id,
    required this.coinId,
    required this.coinName,
    required this.targetPrice,
    required this.isAbove,
    required this.createdAt,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'coinId': coinId,
        'coinName': coinName,
        'targetPrice': targetPrice,
        'isAbove': isAbove,
        'createdAt': createdAt.toIso8601String(),
        'isActive': isActive,
      };

  factory PriceAlert.fromJson(Map<String, dynamic> json) => PriceAlert(
        id: json['id'] as String,
        coinId: json['coinId'] as String,
        coinName: json['coinName'] as String,
        targetPrice: (json['targetPrice'] as num).toDouble(),
        isAbove: json['isAbove'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String),
        isActive: json['isActive'] as bool? ?? true,
      );

  @override
  String toString() => 'Alert: $coinName ${isAbove ? '>' : '<'} \$$targetPrice';
}
