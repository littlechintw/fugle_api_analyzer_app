import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/candle.dart';
import '../../../data/providers/indicator_prefs_provider.dart';
import '../../../indicators/indicators.dart';
import 'indicator_info.dart';

/// K 線 + MA 均線 (+ 可選布林通道) 主圖。
///
/// 滑動圖表會顯示對應的 OHLC + 日期 (crosshair)。
class KLineChart extends StatefulWidget {
  final List<Candle> candles;
  final double height;
  final void Function(int? index)? onHover;
  final List<Candle>? indexCandles;
  final IndicatorPrefs prefs;

  const KLineChart({
    super.key,
    required this.candles,
    required this.prefs,
    this.onHover,
    this.height = 300,
    this.indexCandles,
  });

  static const _maColors = [
    Color(0xFFFFD166),
    Color(0xFF06D6A0),
    Color(0xFF118AB2),
    Color(0xFFEF476F),
    Color(0xFF8E9DFF),
  ];

  @override
  State<KLineChart> createState() => _KLineChartState();
}

class _KLineChartState extends State<KLineChart> {
  int? _crosshairIndex;
  bool _showBollinger = false;

  /// 把指數 K 標準化到「個股第一根 close × 指數相對變化」，
  /// 視覺上等同「同期買入指數的價格走勢」
  List<FlSpot> _indexSpots() {
    final idx = widget.indexCandles;
    if (idx == null || idx.isEmpty || widget.candles.isEmpty) {
      return const [];
    }
    final base = widget.candles.first.close;
    final idxBase = idx.first.close;
    if (idxBase <= 0) return const [];
    final byDate = <String, double>{
      for (final c in idx)
        '${c.date.year}-${c.date.month}-${c.date.day}': c.close
    };
    final spots = <FlSpot>[];
    for (var i = 0; i < widget.candles.length; i++) {
      final c = widget.candles[i];
      final key = '${c.date.year}-${c.date.month}-${c.date.day}';
      final v = byDate[key];
      if (v == null) continue;
      spots.add(FlSpot(i.toDouble(), base * v / idxBase));
    }
    return spots;
  }

  static const double _leftReserved = 48;

  @override
  Widget build(BuildContext context) {
    if (widget.candles.length < 5) {
      return SizedBox(
        height: widget.height,
        child: const Center(
          child:
              Text('資料不足', style: TextStyle(color: AppTheme.textSecondary)),
        ),
      );
    }

    final candles = widget.candles;
    final maSeries = [
      for (final p in widget.prefs.maPeriods) Indicators.sma(candles, p),
    ];
    final bollinger = _showBollinger
        ? Indicators.bollinger(
            candles,
            period: widget.prefs.bollingerPeriod,
            k: widget.prefs.bollingerStdDev,
          )
        : null;

    final allHighs = [
      ...candles.map((c) => c.high),
      if (bollinger != null) ...bollinger.upper.where((v) => !v.isNaN),
    ];
    final allLows = [
      ...candles.map((c) => c.low),
      if (bollinger != null) ...bollinger.lower.where((v) => !v.isNaN),
    ];
    final highs = allHighs.reduce((a, b) => a > b ? a : b);
    final lows = allLows.reduce((a, b) => a < b ? a : b);
    final padding = (highs - lows) * 0.06;
    final minY = lows - padding;
    final maxY = highs + padding;

    final shown = _crosshairIndex ?? candles.length - 1;
    final shownCandle =
        shown >= 0 && shown < candles.length ? candles[shown] : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 標題列：日期 + OHLC + 布林切換
        _ChartHeader(
          candle: shownCandle,
          showBollinger: _showBollinger,
          onToggleBollinger: () =>
              setState(() => _showBollinger = !_showBollinger),
        ),
        SizedBox(
          height: widget.height,
          child: LayoutBuilder(
            builder: (ctx, c) {
              return GestureDetector(
                onHorizontalDragStart: (d) => _updateCrosshair(d.localPosition, c.maxWidth),
                onHorizontalDragUpdate: (d) => _updateCrosshair(d.localPosition, c.maxWidth),
                onHorizontalDragEnd: (_) => _clearCrosshair(),
                onTapDown: (d) => _updateCrosshair(d.localPosition, c.maxWidth),
                onLongPressStart: (d) => _updateCrosshair(d.localPosition, c.maxWidth),
                onLongPressMoveUpdate: (d) =>
                    _updateCrosshair(d.localPosition, c.maxWidth),
                onLongPressEnd: (_) => _clearCrosshair(),
                child: Stack(
                  children: [
                    // K 棒層
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _CandlePainter(
                          candles: candles,
                          minY: minY,
                          maxY: maxY,
                        ),
                      ),
                    ),
                    // 主圖：MA + (布林) + 十字游標
                    Positioned.fill(
                      child: LineChart(
                        LineChartData(
                          minX: 0,
                          maxX: (candles.length - 1).toDouble(),
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
                            show: true,
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: _leftReserved,
                                getTitlesWidget: (v, _) => Text(
                                  v.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 10,
                                  ),
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
                            border: Border.all(color: AppTheme.borderColor),
                          ),
                          extraLinesData: ExtraLinesData(
                            verticalLines: _crosshairIndex == null
                                ? const []
                                : [
                                    VerticalLine(
                                      x: _crosshairIndex!.toDouble(),
                                      color: AppTheme.accent
                                          .withValues(alpha: 0.6),
                                      strokeWidth: 0.8,
                                      dashArray: [3, 3],
                                    ),
                                  ],
                          ),
                          lineBarsData: [
                            for (var i = 0; i < maSeries.length; i++)
                              LineChartBarData(
                                spots: _toSpots(maSeries[i]),
                                isCurved: false,
                                color: KLineChart._maColors[i],
                                barWidth: 1.2,
                                dotData: const FlDotData(show: false),
                              ),
                            if (bollinger != null) ...[
                              LineChartBarData(
                                spots: _toSpots(bollinger.upper),
                                isCurved: false,
                                color: AppTheme.accent
                                    .withValues(alpha: 0.7),
                                barWidth: 1.0,
                                dashArray: [3, 3],
                                dotData: const FlDotData(show: false),
                              ),
                              LineChartBarData(
                                spots: _toSpots(bollinger.middle),
                                isCurved: false,
                                color: AppTheme.accent
                                    .withValues(alpha: 0.5),
                                barWidth: 0.8,
                                dotData: const FlDotData(show: false),
                              ),
                              LineChartBarData(
                                spots: _toSpots(bollinger.lower),
                                isCurved: false,
                                color: AppTheme.accent
                                    .withValues(alpha: 0.7),
                                barWidth: 1.0,
                                dashArray: [3, 3],
                                dotData: const FlDotData(show: false),
                              ),
                            ],
                            if (widget.indexCandles != null)
                              LineChartBarData(
                                spots: _indexSpots(),
                                isCurved: false,
                                color: const Color(0xFF8E9DFF),
                                barWidth: 1.2,
                                dashArray: [4, 2],
                                dotData: const FlDotData(show: false),
                              ),
                          ],
                          lineTouchData: const LineTouchData(enabled: false),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        _MaLegend(
          periods: widget.prefs.maPeriods,
          colors: KLineChart._maColors,
        ),
      ],
    );
  }

  void _updateCrosshair(Offset pos, double width) {
    final usable = width - _leftReserved - 6;
    if (usable <= 0) return;
    final relX = pos.dx - _leftReserved;
    if (relX < 0 || relX > usable) return;
    final n = widget.candles.length;
    final slot = usable / n;
    final i = (relX / slot).floor().clamp(0, n - 1);
    if (i != _crosshairIndex) {
      setState(() => _crosshairIndex = i);
      widget.onHover?.call(i);
    }
  }

  void _clearCrosshair() {
    if (_crosshairIndex != null) {
      setState(() => _crosshairIndex = null);
      widget.onHover?.call(null);
    }
  }

  List<FlSpot> _toSpots(List<double> values) {
    final out = <FlSpot>[];
    for (var i = 0; i < values.length; i++) {
      if (!values[i].isNaN) out.add(FlSpot(i.toDouble(), values[i]));
    }
    return out;
  }
}

class _ChartHeader extends StatelessWidget {
  final Candle? candle;
  final bool showBollinger;
  final VoidCallback onToggleBollinger;
  const _ChartHeader({
    required this.candle,
    required this.showBollinger,
    required this.onToggleBollinger,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 2, 6),
      child: Row(
        children: [
          if (candle != null) ...[
            Text(
              Fmt.date(candle!.date),
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 8),
            _kv('開', Fmt.price(candle!.open)),
            _kv('高', Fmt.price(candle!.high),
                color: AppTheme.bullish),
            _kv('低', Fmt.price(candle!.low),
                color: AppTheme.bearish),
            _kv('收', Fmt.price(candle!.close),
                color: candle!.isBullish
                    ? AppTheme.bullish
                    : AppTheme.bearish),
            _kv('量', Fmt.volume(candle!.volume)),
          ],
          const Spacer(),
          // 布林通道切換 + 主圖說明
          InkWell(
            onTap: onToggleBollinger,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: showBollinger
                    ? AppTheme.accent.withValues(alpha: 0.20)
                    : AppTheme.bgSurface,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: showBollinger
                      ? AppTheme.accent
                      : AppTheme.borderColor,
                ),
              ),
              child: Text(
                'BOLL',
                style: TextStyle(
                  color: showBollinger
                      ? AppTheme.accent
                      : AppTheme.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          InkWell(
            onTap: () => showIndicatorInfo(
              context,
              showBollinger
                  ? IndicatorDocs.bollinger
                  : IndicatorDocs.ma,
            ),
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.info_outline,
                  size: 16, color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(k,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 10,
              )),
          const SizedBox(width: 2),
          Text(v,
              style: TextStyle(
                color: color ?? AppTheme.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              )),
        ],
      ),
    );
  }
}

class _CandlePainter extends CustomPainter {
  final List<Candle> candles;
  final double minY;
  final double maxY;
  _CandlePainter({
    required this.candles,
    required this.minY,
    required this.maxY,
  });

  static const double _leftReserved = 48;

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;
    final usableWidth = size.width - _leftReserved - 6;
    if (usableWidth <= 0) return;
    final n = candles.length;
    final slot = usableWidth / n;
    final bodyWidth = (slot * 0.72).clamp(1.0, 12.0);
    final range = (maxY - minY).abs() < 1e-9 ? 1 : maxY - minY;

    double yFor(double v) =>
        size.height - ((v - minY) / range) * size.height;

    for (var i = 0; i < n; i++) {
      final c = candles[i];
      final cx = _leftReserved + slot * (i + 0.5);
      final color = c.isBullish ? AppTheme.bullish : AppTheme.bearish;
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      final stroke = Paint()
        ..color = color
        ..strokeWidth = 1;

      canvas.drawLine(
        Offset(cx, yFor(c.high)),
        Offset(cx, yFor(c.low)),
        stroke,
      );
      final top = yFor(c.isBullish ? c.close : c.open);
      final bot = yFor(c.isBullish ? c.open : c.close);
      final rect = Rect.fromLTRB(
        cx - bodyWidth / 2,
        top,
        cx + bodyWidth / 2,
        bot < top + 1 ? top + 1 : bot,
      );
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CandlePainter old) =>
      old.candles != candles || old.minY != minY || old.maxY != maxY;
}

class _MaLegend extends StatelessWidget {
  final List<int> periods;
  final List<Color> colors;
  const _MaLegend({required this.periods, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: [
        for (var i = 0; i < periods.length; i++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 10, height: 2, color: colors[i]),
              const SizedBox(width: 4),
              Text(
                'MA${periods[i]}',
                style: TextStyle(color: colors[i], fontSize: 11),
              ),
            ],
          ),
      ],
    );
  }
}
