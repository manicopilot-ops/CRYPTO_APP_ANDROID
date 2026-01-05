import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/price_alerts_provider.dart';
import '../models/price_alert.dart';

class PriceAlertsScreen extends ConsumerWidget {
  const PriceAlertsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(priceAlertsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Price Alerts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear All',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear All Alerts?'),
                  content: const Text(
                      'This will remove all price alerts. This action cannot be undone.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                final service = ref.read(priceAlertsServiceProvider);
                await service.clearAllAlerts();
                ref.invalidate(priceAlertsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All alerts cleared'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: alertsAsync.when(
        data: (alerts) {
          if (alerts.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_off,
                      size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No price alerts set',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text('Create alerts from coin detail screens',
                      style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            );
          }

          // Group alerts by coin
          final groupedAlerts = <String, List<PriceAlert>>{};
          for (final alert in alerts) {
            groupedAlerts.putIfAbsent(alert.coinId, () => []).add(alert);
          }

          return ListView.builder(
            itemCount: groupedAlerts.length,
            itemBuilder: (context, index) {
              final coinId = groupedAlerts.keys.elementAt(index);
              final coinAlerts = groupedAlerts[coinId]!;
              final coinName = coinAlerts.first.coinName;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text(
                      coinName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(coinName,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      '${coinAlerts.length} alert${coinAlerts.length > 1 ? 's' : ''}'),
                  children: coinAlerts.map((alert) {
                    return ListTile(
                      leading: Icon(
                        alert.isAbove ? Icons.trending_up : Icons.trending_down,
                        color: alert.isAbove ? Colors.green : Colors.red,
                      ),
                      title: Text(
                        '${alert.isAbove ? 'Above' : 'Below'} \$${alert.targetPrice.toStringAsFixed(2)}',
                      ),
                      subtitle: Text(_formatDate(alert.createdAt)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!alert.isActive)
                            Chip(
                              label: const Text('Triggered',
                                  style: TextStyle(fontSize: 10)),
                              backgroundColor: Colors.orange[100],
                              padding: EdgeInsets.zero,
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final service =
                                  ref.read(priceAlertsServiceProvider);
                              await service.removeAlert(alert.id);
                              ref.invalidate(priceAlertsProvider);
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.pushNamed(context, '/detail', arguments: {
                          'id': alert.coinId,
                          'name': alert.coinName,
                        });
                      },
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading alerts: $e'),
            ],
          ),
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
