import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/price_point.dart';

class PriceChart extends StatelessWidget {
  final List<PricePoint> points;
  final String chartType; // 'price', 'volume', 'marketcap'

  const PriceChart({
    Key? key,
    required this.points,
    this.chartType = 'price',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const Center(child: Text('No data'));

    // Get values based on chart type
    final values = points.map((p) {
      switch (chartType) {
        case 'volume':
          return p.volume ?? 0.0;
        case 'marketcap':
          return p.marketCap ?? 0.0;
        default:
          return p.price;
      }
    }).toList();

    final spots = values
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY) * 0.1;

    // Chart colors based on type
    Color chartColor;
    Color gradientStart;
    Color gradientEnd;

    switch (chartType) {
      case 'volume':
        chartColor = Colors.orange;
        gradientStart = Colors.orange.withValues(alpha: 0.5);
        gradientEnd = Colors.orange.withValues(alpha: 0.0);
        break;
      case 'marketcap':
        chartColor = Colors.purple;
        gradientStart = Colors.purple.withValues(alpha: 0.5);
        gradientEnd = Colors.purple.withValues(alpha: 0.0);
        break;
      default:
        chartColor = Colors.green;
        gradientStart = Colors.green.withValues(alpha: 0.5);
        gradientEnd = Colors.green.withValues(alpha: 0.0);
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (spots.length - 1).toDouble(),
          minY: minY - padding,
          maxY: maxY + padding,
          titlesData: FlTitlesData(
            bottomTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 60,
                getTitlesWidget: (value, meta) {
                  return Text(
                    NumberFormat.compact().format(value),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  );
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxY - minY) / 5,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withValues(alpha: 0.15),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (spot) => Colors.white.withValues(alpha: 0.95),
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              tooltipPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              tooltipBorder: const BorderSide(color: Colors.grey, width: 1),
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final idx = spot.x.toInt().clamp(0, points.length - 1);
                  final point = points[idx];
                  final dateStr = DateFormat('MMM d, HH:mm').format(point.time);

                  String mainValue;
                  switch (chartType) {
                    case 'volume':
                      mainValue =
                          'Vol: \$${NumberFormat.compact().format(point.volume ?? 0)}';
                      break;
                    case 'marketcap':
                      mainValue =
                          'Cap: \$${NumberFormat.compact().format(point.marketCap ?? 0)}';
                      break;
                    default:
                      mainValue = 'Price: \$${point.price.toStringAsFixed(2)}';
                  }

                  return LineTooltipItem(
                    '$dateStr\n',
                    const TextStyle(color: Colors.black54, fontSize: 11),
                    children: [
                      TextSpan(
                        text: mainValue,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ],
                  );
                }).toList();
              },
            ),
            handleBuiltInTouches: true,
            getTouchedSpotIndicator: (barData, spotIndexes) {
              return spotIndexes.map((index) {
                return TouchedSpotIndicatorData(
                  FlLine(color: chartColor, strokeWidth: 2, dashArray: [3, 3]),
                  FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) =>
                        FlDotCirclePainter(
                      radius: 5,
                      color: Colors.white,
                      strokeWidth: 2,
                      strokeColor: chartColor,
                    ),
                  ),
                );
              }).toList();
            },
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              preventCurveOverShooting: true,
              dotData: const FlDotData(show: false),
              color: chartColor,
              barWidth: 2.5,
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [gradientStart, gradientEnd],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
