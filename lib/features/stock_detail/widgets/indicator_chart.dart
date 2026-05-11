import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/candle.dart';
import '../../../indicators/indicators.dart';
import 'indicator_info.dart';

enum SubIndicator { bias, rsi, macd, kd, williams }

extension SubIndicatorMeta on SubIndicator {
  String get label => switch (this) {
        SubIndicator.bias => 'BIAS',
        SubIndicator.rsi => 'RSI',
        SubIndicator.macd => 'MACD',
        SubIndicator.kd => 'KD',
        SubIndicator.williams => 'W%R',
      };

  String get subtitle => switch (this) {
        SubIndicator.bias => '20 日乖離率',
        SubIndicator.rsi => 'RSI(14)',
        SubIndicator.macd => 'MACD(12, 26, 9)',
        SubIndicator.kd => 'KD(9, 3, 3)',
        SubIndicator.williams => 'Williams %R(14)',
      };

  IndicatorDoc get doc => switch (this) {
        SubIndicator.bias => IndicatorDocs.bias,
        SubIndicator.rsi => IndicatorDocs.rsi,
        SubIndicator.macd => IndicatorDocs.macd,
        SubIndicator.kd => IndicatorDocs.kd,
        SubIndicator.williams => IndicatorDocs.williams,
      };
}

class IndicatorChart extends StatefulWidget {
  final List<Candle> candles;
  final double height;
  final int? highlightIndex; // 來自十字游標
  const IndicatorChart({
    super.key,
    required this.candles,
    this.highlightIndex,
    this.height = 160,
  });

  @override
  State<IndicatorChart> createState() => _IndicatorChartState();
}

class _IndicatorChartState extends State<IndicatorChart> {
  SubIndicator _selected = SubIndicator.macd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 指標切換列
        SizedBox(
          height: 32,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final s in SubIndicator.values)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(s.label,
                        style: const TextStyle(fontSize: 11)),
                    selected: _selected == s,
                    onSelected: (_) => setState(() => _selected = s),
                    backgroundColor: AppTheme.bgSurface,
                    selectedColor: AppTheme.accent.withValues(alpha: 0.18),
                    labelStyle: TextStyle(
                      color: _selected == s
                          ? AppTheme.accent
                          : AppTheme.textSecondary,
                    ),
                    side: BorderSide(
                      color: _selected == s
                          ? AppTheme.accent
                          : AppTheme.borderColor,
                    ),
                    materialTapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
        ),
        // 標題 + 數值 + ⓘ
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: Row(
            children: [
              Text(
                _selected.subtitle,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(width: 8),
              _ValueAt(
                  selected: _selected,
                  candles: widget.candles,
                  index: widget.highlightIndex),
              const Spacer(),
              InkWell(
                onTap: () => showIndicatorInfo(context, _selected.doc),
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.info_outline,
                      size: 16, color: AppTheme.textSecondary),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: widget.height, child: _buildChart()),
      ],
    );
  }

  Widget _buildChart() {
    switch (_selected) {
      case SubIndicator.bias:
        return _OscChart(
          values: Indicators.bias(widget.candles, 20),
          zeroLine: 0,
          warningHigh: 8,
          warningLow: -8,
          color: AppTheme.accent,
          highlightIndex: widget.highlightIndex,
        );
      case SubIndicator.rsi:
        return _OscChart(
          values: Indicators.rsi(widget.candles),
          zeroLine: 50,
          warningHigh: 70,
          warningLow: 30,
          color: const Color(0xFF118AB2),
          fixedMin: 0,
          fixedMax: 100,
          highlightIndex: widget.highlightIndex,
        );
      case SubIndicator.macd:
        return _MacdChart(
          macd: Indicators.macd(widget.candles),
          highlightIndex: widget.highlightIndex,
        );
      case SubIndicator.kd:
        final kd = Indicators.kd(widget.candles);
        return _TwoLineOscChart(
          line1: kd.k,
          line2: kd.d,
          color1: const Color(0xFFFFD166),
          color2: const Color(0xFF06D6A0),
          label1: 'K',
          label2: 'D',
          fixedMin: 0,
          fixedMax: 100,
          highBand: 80,
          lowBand: 20,
          highlightIndex: widget.highlightIndex,
        );
      case SubIndicator.williams:
        return _OscChart(
          values: Indicators.williamsR(widget.candles),
          zeroLine: -50,
          warningHigh: -20,
          warningLow: -80,
          color: const Color(0xFFEF476F),
          fixedMin: -100,
          fixedMax: 0,
          highlightIndex: widget.highlightIndex,
        );
    }
  }
}

class _ValueAt extends StatelessWidget {
  final SubIndicator selected;
  final List<Candle> candles;
  final int? index;
  const _ValueAt({
    required this.selected,
    required this.candles,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final i = index ?? candles.length - 1;
    if (i < 0 || i >= candles.length) return const SizedBox.shrink();
    String text;
    switch (selected) {
      case SubIndicator.bias:
        final v = Indicators.bias(candles, 20)[i];
        text = v.isNaN ? '' : v.toStringAsFixed(2);
        break;
      case SubIndicator.rsi:
        final v = Indicators.rsi(candles)[i];
        text = v.isNaN ? '' : v.toStringAsFixed(1);
        break;
      case SubIndicator.macd:
        final m = Indicators.macd(candles);
        final dif = m.dif[i], dea = m.dea[i], h = m.histogram[i];
        text = _anyNaN([dif, dea, h])
            ? ''
            : 'DIF ${dif.toStringAsFixed(2)}  DEA ${dea.toStringAsFixed(2)}';
        break;
      case SubIndicator.kd:
        final kd = Indicators.kd(candles);
        final k = kd.k[i], d = kd.d[i];
        text = _anyNaN([k, d])
            ? ''
            : 'K ${k.toStringAsFixed(1)}  D ${d.toStringAsFixed(1)}';
        break;
      case SubIndicator.williams:
        final v = Indicators.williamsR(candles)[i];
        text = v.isNaN ? '' : '${v.toStringAsFixed(1)}';
        break;
    }
    if (text.isEmpty) return const SizedBox.shrink();
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.accent,
        fontSize: 11,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
  }

  static bool _anyNaN(List<double> xs) => xs.any((e) => e.isNaN);
}

class _OscChart extends StatelessWidget {
  final List<double> values;
  final double zeroLine;
  final double warningHigh;
  final double warningLow;
  final Color color;
  final double? fixedMin;
  final double? fixedMax;
  final int? highlightIndex;
  const _OscChart({
    required this.values,
    required this.zeroLine,
    required this.warningHigh,
    required this.warningLow,
    required this.color,
    this.fixedMin,
    this.fixedMax,
    this.highlightIndex,
  });

  @override
  Widget build(BuildContext context) {
    final clean = values.where((v) => !v.isNaN).toList();
    if (clean.isEmpty) {
      return const Center(
        child: Text('—', style: TextStyle(color: AppTheme.textSecondary)),
      );
    }
    final cMin = clean.reduce((a, b) => a < b ? a : b);
    final cMax = clean.reduce((a, b) => a > b ? a : b);
    final minY = fixedMin ?? (cMin - 2);
    final maxY = fixedMax ?? (cMax + 2);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (values.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: AppTheme.borderColor),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (v, _) => Text(
                v.toStringAsFixed(0),
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 10),
              ),
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: zeroLine,
              color: AppTheme.textSecondary.withValues(alpha: 0.5),
              strokeWidth: 0.6,
              dashArray: [4, 4],
            ),
            HorizontalLine(
              y: warningHigh,
              color: AppTheme.bullish.withValues(alpha: 0.5),
              strokeWidth: 0.6,
              dashArray: [4, 4],
            ),
            HorizontalLine(
              y: warningLow,
              color: AppTheme.bearish.withValues(alpha: 0.5),
              strokeWidth: 0.6,
              dashArray: [4, 4],
            ),
          ],
          verticalLines: highlightIndex == null
              ? const []
              : [
                  VerticalLine(
                    x: highlightIndex!.toDouble(),
                    color: AppTheme.accent.withValues(alpha: 0.5),
                    strokeWidth: 0.8,
                    dashArray: [3, 3],
                  ),
                ],
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < values.length; i++)
                if (!values[i].isNaN) FlSpot(i.toDouble(), values[i])
            ],
            color: color,
            barWidth: 1.4,
            isCurved: false,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.10),
            ),
          ),
        ],
        lineTouchData: const LineTouchData(enabled: false),
      ),
    );
  }
}

class _TwoLineOscChart extends StatelessWidget {
  final List<double> line1;
  final List<double> line2;
  final Color color1;
  final Color color2;
  final String label1;
  final String label2;
  final double fixedMin;
  final double fixedMax;
  final double highBand;
  final double lowBand;
  final int? highlightIndex;
  const _TwoLineOscChart({
    required this.line1,
    required this.line2,
    required this.color1,
    required this.color2,
    required this.label1,
    required this.label2,
    required this.fixedMin,
    required this.fixedMax,
    required this.highBand,
    required this.lowBand,
    this.highlightIndex,
  });

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (line1.length - 1).toDouble(),
        minY: fixedMin,
        maxY: fixedMax,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: AppTheme.borderColor),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (v, _) => Text(
                v.toStringAsFixed(0),
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 10),
              ),
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: highBand,
              color: AppTheme.bullish.withValues(alpha: 0.5),
              strokeWidth: 0.6,
              dashArray: [4, 4],
            ),
            HorizontalLine(
              y: lowBand,
              color: AppTheme.bearish.withValues(alpha: 0.5),
              strokeWidth: 0.6,
              dashArray: [4, 4],
            ),
          ],
          verticalLines: highlightIndex == null
              ? const []
              : [
                  VerticalLine(
                    x: highlightIndex!.toDouble(),
                    color: AppTheme.accent.withValues(alpha: 0.5),
                    strokeWidth: 0.8,
                    dashArray: [3, 3],
                  ),
                ],
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < line1.length; i++)
                if (!line1[i].isNaN) FlSpot(i.toDouble(), line1[i])
            ],
            color: color1,
            barWidth: 1.4,
            isCurved: false,
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            spots: [
              for (var i = 0; i < line2.length; i++)
                if (!line2[i].isNaN) FlSpot(i.toDouble(), line2[i])
            ],
            color: color2,
            barWidth: 1.4,
            isCurved: false,
            dotData: const FlDotData(show: false),
          ),
        ],
        lineTouchData: const LineTouchData(enabled: false),
      ),
    );
  }
}

class _MacdChart extends StatelessWidget {
  final MacdResult macd;
  final int? highlightIndex;
  const _MacdChart({required this.macd, this.highlightIndex});

  @override
  Widget build(BuildContext context) {
    final all = [
      ...macd.dif.where((v) => !v.isNaN),
      ...macd.dea.where((v) => !v.isNaN),
      ...macd.histogram.where((v) => !v.isNaN),
    ];
    if (all.isEmpty) {
      return const Center(
        child: Text('—', style: TextStyle(color: AppTheme.textSecondary)),
      );
    }
    final mn = all.reduce((a, b) => a < b ? a : b);
    final mx = all.reduce((a, b) => a > b ? a : b);
    final pad = (mx - mn).abs() * 0.1 + 0.1;
    final minY = mn - pad;
    final maxY = mx + pad;

    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _HistogramPainter(
              values: macd.histogram,
              minY: minY,
              maxY: maxY,
            ),
          ),
        ),
        Positioned.fill(
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: (macd.dif.length - 1).toDouble(),
              minY: minY,
              maxY: maxY,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: AppTheme.borderColor),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (v, _) => Text(
                      v.toStringAsFixed(1),
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 10),
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
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: 0,
                    color: AppTheme.textSecondary.withValues(alpha: 0.5),
                    strokeWidth: 0.6,
                    dashArray: [4, 4],
                  ),
                ],
                verticalLines: highlightIndex == null
                    ? const []
                    : [
                        VerticalLine(
                          x: highlightIndex!.toDouble(),
                          color: AppTheme.accent.withValues(alpha: 0.5),
                          strokeWidth: 0.8,
                          dashArray: [3, 3],
                        ),
                      ],
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    for (var i = 0; i < macd.dif.length; i++)
                      if (!macd.dif[i].isNaN) FlSpot(i.toDouble(), macd.dif[i])
                  ],
                  color: const Color(0xFFFFD166),
                  barWidth: 1.2,
                  isCurved: false,
                  dotData: const FlDotData(show: false),
                ),
                LineChartBarData(
                  spots: [
                    for (var i = 0; i < macd.dea.length; i++)
                      if (!macd.dea[i].isNaN) FlSpot(i.toDouble(), macd.dea[i])
                  ],
                  color: const Color(0xFF06D6A0),
                  barWidth: 1.2,
                  isCurved: false,
                  dotData: const FlDotData(show: false),
                ),
              ],
              lineTouchData: const LineTouchData(enabled: false),
            ),
          ),
        ),
      ],
    );
  }
}

class _HistogramPainter extends CustomPainter {
  final List<double> values;
  final double minY;
  final double maxY;
  _HistogramPainter({
    required this.values,
    required this.minY,
    required this.maxY,
  });

  static const double _leftReserved = 36;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final usableWidth = size.width - _leftReserved - 6;
    if (usableWidth <= 0) return;
    final slot = usableWidth / values.length;
    final range = (maxY - minY).abs() < 1e-9 ? 1 : maxY - minY;
    double yFor(double v) =>
        size.height - ((v - minY) / range) * size.height;
    final zeroY = yFor(0);

    for (var i = 0; i < values.length; i++) {
      final v = values[i];
      if (v.isNaN) continue;
      final cx = _leftReserved + slot * (i + 0.5);
      final paint = Paint()
        ..color = v >= 0
            ? AppTheme.bullish.withValues(alpha: 0.6)
            : AppTheme.bearish.withValues(alpha: 0.6);
      final y = yFor(v);
      final rect = Rect.fromLTRB(
        cx - slot * 0.35,
        v >= 0 ? y : zeroY,
        cx + slot * 0.35,
        v >= 0 ? zeroY : y,
      );
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HistogramPainter old) =>
      old.values != values || old.minY != minY || old.maxY != maxY;
}
