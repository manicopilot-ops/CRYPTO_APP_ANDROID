import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/candle_data.dart';

class CandlestickChart extends StatefulWidget {
  final List<CandleData> candles;

  const CandlestickChart({
    Key? key,
    required this.candles,
  }) : super(key: key);

  @override
  State<CandlestickChart> createState() => _CandlestickChartState();
}

class _CandlestickChartState extends State<CandlestickChart> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.candles.isEmpty) return const Center(child: Text('No data'));

    final minPrice =
        widget.candles.map((c) => c.low).reduce((a, b) => a < b ? a : b);
    final maxPrice =
        widget.candles.map((c) => c.high).reduce((a, b) => a > b ? a : b);
    final padding = (maxPrice - minPrice) * 0.1;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Stack(
        children: [
          // График свечей
          LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onTapDown: (details) {
                  _updateHoveredIndex(details.localPosition, constraints);
                },
                onPanUpdate: (details) {
                  _updateHoveredIndex(details.localPosition, constraints);
                },
                onPanEnd: (_) {
                  setState(() => _hoveredIndex = null);
                },
                child: CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: CandlestickPainter(
                    candles: widget.candles,
                    minPrice: minPrice - padding,
                    maxPrice: maxPrice + padding,
                    hoveredIndex: _hoveredIndex,
                  ),
                ),
              );
            },
          ),

          // Tooltip для выбранной свечи (поверх графика)
          if (_hoveredIndex != null && _hoveredIndex! < widget.candles.length)
            Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C3E).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF3B3B54)),
                  ),
                  child: isLandscape
                      ? _buildCandleInfo(widget.candles[_hoveredIndex!])
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child:
                              _buildCandleInfo(widget.candles[_hoveredIndex!]),
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _updateHoveredIndex(Offset position, BoxConstraints constraints) {
    final candleWidth = constraints.maxWidth / widget.candles.length;
    final index = (position.dx / candleWidth).floor();

    if (index >= 0 && index < widget.candles.length) {
      setState(() => _hoveredIndex = index);
    }
  }

  Widget _buildCandleInfo(CandleData candle) {
    final isGreen = candle.close >= candle.open;
    final change = candle.close - candle.open;
    final changePercent = (change / candle.open) * 100;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              DateFormat('MMM d, HH:mm').format(candle.time),
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${isGreen ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
              style: TextStyle(
                fontSize: 9,
                color: isGreen ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        _buildInfoItem('O', candle.open, Colors.grey[700]!),
        const SizedBox(width: 5),
        _buildInfoItem('H', candle.high, Colors.green),
        const SizedBox(width: 5),
        _buildInfoItem('L', candle.low, Colors.red),
        const SizedBox(width: 5),
        _buildInfoItem('C', candle.close, isGreen ? Colors.green : Colors.red),
      ],
    );
  }

  Widget _buildInfoItem(String label, double value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            color: Colors.grey[600],
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '\$${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 9,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class CandlestickPainter extends CustomPainter {
  final List<CandleData> candles;
  final double minPrice;
  final double maxPrice;
  final int? hoveredIndex;

  CandlestickPainter({
    required this.candles,
    required this.minPrice,
    required this.maxPrice,
    this.hoveredIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    final priceRange = maxPrice - minPrice;
    final candleWidth = size.width / candles.length;
    final bodyWidth = candleWidth * 0.7;
    final wickWidth = 2.0;

    // Рисуем горизонтальные линии сетки
    _drawGrid(canvas, size);

    // Рисуем ценовые метки слева
    _drawPriceLabels(canvas, size);

    // Рисуем свечи
    for (int i = 0; i < candles.length; i++) {
      final candle = candles[i];
      final x = (i + 0.5) * candleWidth;

      final isGreen = candle.close >= candle.open;
      final color = isGreen ? Colors.green : Colors.red;
      final isHovered = i == hoveredIndex;

      // Координаты Y (инвертируем, т.к. canvas рисует сверху вниз)
      final highY = _priceToY(candle.high, size.height);
      final lowY = _priceToY(candle.low, size.height);
      final openY = _priceToY(candle.open, size.height);
      final closeY = _priceToY(candle.close, size.height);

      // Рисуем фитиль (wick) - тонкая линия от high до low
      final wickPaint = Paint()
        ..color = color.withOpacity(isHovered ? 1.0 : 0.8)
        ..strokeWidth = wickWidth
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(x, highY),
        Offset(x, lowY),
        wickPaint,
      );

      // Рисуем тело свечи (body)
      final bodyTop = isGreen ? closeY : openY;
      final bodyBottom = isGreen ? openY : closeY;
      final bodyHeight = (bodyBottom - bodyTop).abs();

      final bodyPaint = Paint()
        ..color = isHovered ? color : color.withOpacity(0.9)
        ..style = isGreen ? PaintingStyle.fill : PaintingStyle.fill;

      // Если тело очень маленькое (цена почти не изменилась), рисуем линию
      if (bodyHeight < 2) {
        canvas.drawLine(
          Offset(x - bodyWidth / 2, bodyTop),
          Offset(x + bodyWidth / 2, bodyTop),
          Paint()
            ..color = Colors.grey[600]!
            ..strokeWidth = 2,
        );
      } else {
        // Рисуем прямоугольное тело
        final rect = Rect.fromLTWH(
          x - bodyWidth / 2,
          bodyTop,
          bodyWidth,
          bodyHeight,
        );

        if (isGreen) {
          // Зеленая свеча - заполненная
          canvas.drawRect(rect, bodyPaint);
        } else {
          // Красная свеча - заполненная
          canvas.drawRect(rect, bodyPaint);
        }
      }

      // Подсветка при наведении
      if (isHovered) {
        final highlightPaint = Paint()
          ..color = Colors.blue.withOpacity(0.2)
          ..style = PaintingStyle.fill;

        canvas.drawRect(
          Rect.fromLTWH(x - candleWidth / 2, 0, candleWidth, size.height),
          highlightPaint,
        );
      }
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1;

    // Рисуем 5 горизонтальных линий
    for (int i = 0; i <= 5; i++) {
      final y = (size.height / 5) * i;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }
  }

  void _drawPriceLabels(Canvas canvas, Size size) {
    final textStyle = TextStyle(
      color: Colors.grey[600],
      fontSize: 11,
    );

    final priceRange = maxPrice - minPrice;

    // Рисуем 6 ценовых меток
    for (int i = 0; i <= 5; i++) {
      final price = maxPrice - (priceRange / 5) * i;
      final y = (size.height / 5) * i;

      final textSpan = TextSpan(
        text: '\$${NumberFormat.compact().format(price)}',
        style: textStyle,
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: ui.TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
          canvas, Offset(-textPainter.width - 8, y - textPainter.height / 2));
    }
  }

  double _priceToY(double price, double height) {
    final priceRange = maxPrice - minPrice;
    final normalizedPrice = (price - minPrice) / priceRange;
    return height - (normalizedPrice * height); // Инвертируем Y
  }

  @override
  bool shouldRepaint(CandlestickPainter oldDelegate) {
    return oldDelegate.candles != candles ||
        oldDelegate.minPrice != minPrice ||
        oldDelegate.maxPrice != maxPrice ||
        oldDelegate.hoveredIndex != hoveredIndex;
  }
}
