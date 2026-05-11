import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/intraday_candle.dart';

/// 當日分時走勢圖
///
/// 上半部：成交價折線（含均價）
/// 下半部：成交量柱狀
class IntradayChart extends StatefulWidget {
  final List<IntradayCandle> candles;
  final double referencePrice; // 昨收價，用於漲跌色與基準線
  final double height;
  const IntradayChart({
    super.key,
    required this.candles,
    required this.referencePrice,
    this.height = 220,
  });

  @override
  State<IntradayChart> createState() => _IntradayChartState();
}

class _IntradayChartState extends State<IntradayChart> {
  int? _hoverIndex;

  static final _timeFmt = DateFormat('HH:mm');

  @override
  Widget build(BuildContext context) {
    if (widget.candles.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: const Center(
          child: Text('尚無當日資料 (盤後或休市)',
              style: TextStyle(color: AppTheme.textSecondary)),
        ),
      );
    }

    final priceMin = [
      widget.referencePrice,
      ...widget.candles.map((c) => c.low),
    ].reduce((a, b) => a < b ? a : b);
    final priceMax = [
      widget.referencePrice,
      ...widget.candles.map((c) => c.high),
    ].reduce((a, b) => a > b ? a : b);
    final pad = (priceMax - priceMin) * 0.08 + 0.01;
    final minY = priceMin - pad;
    final maxY = priceMax + pad;

    final volMax = widget.candles.map((c) => c.volume).reduce(
        (a, b) => a > b ? a : b);

    final shown = _hoverIndex == null
        ? widget.candles.last
        : widget.candles[_hoverIndex!.clamp(0, widget.candles.length - 1)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(
          candle: shown,
          referencePrice: widget.referencePrice,
        ),
        SizedBox(
          height: widget.height,
          child: LayoutBuilder(
            builder: (ctx, c) {
              return GestureDetector(
                onHorizontalDragUpdate: (d) =>
                    _updateHover(d.localPosition, c.maxWidth),
                onHorizontalDragEnd: (_) => setState(() => _hoverIndex = null),
                onTapDown: (d) => _updateHover(d.localPosition, c.maxWidth),
                onLongPressStart: (d) =>
                    _updateHover(d.localPosition, c.maxWidth),
                onLongPressMoveUpdate: (d) =>
                    _updateHover(d.localPosition, c.maxWidth),
                onLongPressEnd: (_) =>
                    setState(() => _hoverIndex = null),
                child: Column(
                  children: [
                    Expanded(
                      flex: 3,
                      child: LineChart(
                        LineChartData(
                          minX: 0,
                          maxX: (widget.candles.length - 1).toDouble(),
                          minY: minY,
                          maxY: maxY,
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: (maxY - minY) / 4,
                            getDrawingHorizontalLine: (_) => const FlLine(
                              color: AppTheme.borderColor,
                              strokeWidth: 0.5,
                              dashArray: [4, 4],
                            ),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 48,
                                getTitlesWidget: (v, _) => Text(
                                  v.toStringAsFixed(1),
                                  style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 10),
                                ),
                              ),
                            ),
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border:
                                Border.all(color: AppTheme.borderColor),
                          ),
                          extraLinesData: ExtraLinesData(
                            horizontalLines: [
                              HorizontalLine(
                                y: widget.referencePrice,
                                color: AppTheme.textSecondary
                                    .withValues(alpha: 0.5),
                                strokeWidth: 0.6,
                                dashArray: [4, 4],
                              ),
                            ],
                            verticalLines: _hoverIndex == null
                                ? const []
                                : [
                                    VerticalLine(
                                      x: _hoverIndex!.toDouble(),
                                      color: AppTheme.accent
                                          .withValues(alpha: 0.6),
                                      strokeWidth: 0.8,
                                      dashArray: [3, 3],
                                    ),
                                  ],
                          ),
                          lineBarsData: [
                            // 成交價
                            LineChartBarData(
                              spots: [
                                for (var i = 0;
                                    i < widget.candles.length;
                                    i++)
                                  FlSpot(i.toDouble(),
                                      widget.candles[i].close),
                              ],
                              color: _trendColor(widget.candles.last.close),
                              barWidth: 1.4,
                              isCurved: false,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: _trendColor(widget.candles.last.close)
                                    .withValues(alpha: 0.08),
                              ),
                            ),
                            // VWAP 均價（若有）
                            if (widget.candles.any((c) => c.average != null))
                              LineChartBarData(
                                spots: [
                                  for (var i = 0;
                                      i < widget.candles.length;
                                      i++)
                                    if (widget.candles[i].average != null)
                                      FlSpot(i.toDouble(),
                                          widget.candles[i].average!),
                                ],
                                color: const Color(0xFFFFD166),
                                barWidth: 0.8,
                                isCurved: false,
                                dashArray: [3, 3],
                                dotData: const FlDotData(show: false),
                              ),
                          ],
                          lineTouchData:
                              const LineTouchData(enabled: false),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: _VolumeBarPainter(
                          candles: widget.candles,
                          maxVol: volMax,
                          referencePrice: widget.referencePrice,
                          hoverIndex: _hoverIndex,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.candles.isEmpty
                  ? ''
                  : _timeFmt.format(widget.candles.first.time),
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 10),
            ),
            const Text(
              '⋯⋯ 均價 (VWAP)',
              style: TextStyle(
                  color: Color(0xFFFFD166), fontSize: 10),
            ),
            Text(
              widget.candles.isEmpty
                  ? ''
                  : _timeFmt.format(widget.candles.last.time),
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }

  Color _trendColor(double price) =>
      price >= widget.referencePrice ? AppTheme.bullish : AppTheme.bearish;

  void _updateHover(Offset pos, double width) {
    const left = 48.0;
    final usable = width - left - 6;
    if (usable <= 0) return;
    final relX = pos.dx - left;
    if (relX < 0 || relX > usable) return;
    final n = widget.candles.length;
    final i = ((relX / usable) * n).floor().clamp(0, n - 1);
    if (i != _hoverIndex) setState(() => _hoverIndex = i);
  }
}

class _Header extends StatelessWidget {
  final IntradayCandle candle;
  final double referencePrice;
  const _Header({required this.candle, required this.referencePrice});

  static final _fmt = DateFormat('HH:mm');

  @override
  Widget build(BuildContext context) {
    final change = candle.close - referencePrice;
    final pct = referencePrice == 0 ? 0.0 : change / referencePrice * 100;
    final color = change > 0
        ? AppTheme.bullish
        : (change < 0 ? AppTheme.bearish : AppTheme.neutral);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      child: Row(
        children: [
          Text(
            _fmt.format(candle.time),
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 11),
          ),
          const SizedBox(width: 8),
          Text(
            Fmt.price(candle.close),
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}  '
            '(${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(2)}%)',
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          if (candle.average != null)
            Text(
              '均 ${Fmt.price(candle.average!)}',
              style: const TextStyle(
                  color: Color(0xFFFFD166), fontSize: 11),
            ),
          const SizedBox(width: 10),
          Text(
            '量 ${Fmt.volume(candle.volume)}',
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _VolumeBarPainter extends CustomPainter {
  final List<IntradayCandle> candles;
  final double maxVol;
  final double referencePrice;
  final int? hoverIndex;
  _VolumeBarPainter({
    required this.candles,
    required this.maxVol,
    required this.referencePrice,
    this.hoverIndex,
  });

  static const double _leftReserved = 48;

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty || maxVol <= 0) return;
    final usableWidth = size.width - _leftReserved - 6;
    final slot = usableWidth / candles.length;

    final border = Paint()
      ..color = AppTheme.borderColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawRect(
        Rect.fromLTRB(_leftReserved, 0, size.width - 6, size.height), border);

    for (var i = 0; i < candles.length; i++) {
      final v = candles[i].volume;
      if (v <= 0) continue;
      final h = (v / maxVol) * size.height * 0.94;
      final cx = _leftReserved + slot * (i + 0.5);
      final paint = Paint()
        ..color = (candles[i].close >= referencePrice
                ? AppTheme.bullish
                : AppTheme.bearish)
            .withValues(alpha: 0.6);
      canvas.drawRect(
        Rect.fromLTRB(cx - slot * 0.35, size.height - h, cx + slot * 0.35,
            size.height),
        paint,
      );
    }
    if (hoverIndex != null && hoverIndex! < candles.length) {
      final cx = _leftReserved + slot * (hoverIndex! + 0.5);
      final dashPaint = Paint()
        ..color = AppTheme.accent.withValues(alpha: 0.6)
        ..strokeWidth = 0.8;
      canvas.drawLine(
          Offset(cx, 0), Offset(cx, size.height), dashPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _VolumeBarPainter old) =>
      old.candles != candles ||
      old.maxVol != maxVol ||
      old.hoverIndex != hoverIndex;
}
