import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/price_point.dart';

class PriceChart extends StatelessWidget {
  final List<PricePoint> points;
  const PriceChart({Key? key, required this.points}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const Center(child: Text('No data'));
    final spots = points
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.price))
        .toList();
    final minY = points.map((p) => p.price).reduce((a, b) => a < b ? a : b);
    final maxY = points.map((p) => p.price).reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY) * 0.1;

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
                  return LineTooltipItem(
                    '$dateStr\n',
                    const TextStyle(color: Colors.black54, fontSize: 11),
                    children: [
                      TextSpan(
                        text: 'Price: \$${point.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      TextSpan(
                        text:
                            '\nVol: \$${NumberFormat.compact().format(point.price * 1000000)}',
                        style: const TextStyle(
                            fontSize: 10, color: Colors.black54),
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
                  const FlLine(
                      color: Colors.green, strokeWidth: 2, dashArray: [3, 3]),
                  FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) =>
                        FlDotCirclePainter(
                      radius: 5,
                      color: Colors.white,
                      strokeWidth: 2,
                      strokeColor: Colors.green,
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
              gradient: const LinearGradient(
                colors: [Color(0xFF00C853), Color(0xFF64DD17)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              barWidth: 2.5,
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF00C853).withValues(alpha: 0.3),
                    const Color(0xFF64DD17).withValues(alpha: 0.05),
                  ],
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
