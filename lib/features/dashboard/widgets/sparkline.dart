import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// 極簡 Sparkline — 自繪，避免引入額外圖表依賴。
class Sparkline extends StatelessWidget {
  /// 已標準化至 0..1 的點，或原始值（任一）
  final List<double> values;
  final Color color;
  final double strokeWidth;
  final bool fill;

  const Sparkline({
    super.key,
    required this.values,
    this.color = AppTheme.accent,
    this.strokeWidth = 1.6,
    this.fill = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SparklinePainter(
        values: values,
        color: color,
        strokeWidth: strokeWidth,
        fill: fill,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final double strokeWidth;
  final bool fill;

  _SparklinePainter({
    required this.values,
    required this.color,
    required this.strokeWidth,
    required this.fill,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final clean = values.where((v) => !v.isNaN).toList();
    if (clean.length < 2) return;

    final lo = clean.reduce((a, b) => a < b ? a : b);
    final hi = clean.reduce((a, b) => a > b ? a : b);
    final range = (hi - lo).abs() < 1e-9 ? 1.0 : hi - lo;
    final dx = size.width / (values.length - 1);

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final v = values[i].isNaN ? lo : values[i];
      final x = dx * i;
      final y = size.height - ((v - lo) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    if (fill) {
      final fillPath = Path.from(path)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(
        fillPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.0)],
          ).createShader(Offset.zero & size),
      );
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.values != values || old.color != color;
}
