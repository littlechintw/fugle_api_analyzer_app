import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../indicators/analysis.dart';

class VolatilityCard extends StatelessWidget {
  final VolatilityReport report;
  const VolatilityCard({super.key, required this.report});

  Color _color() => switch (report.level) {
        VolatilityLevel.low => AppTheme.neutral,
        VolatilityLevel.normal => AppTheme.accent,
        VolatilityLevel.high => AppTheme.bullish,
        VolatilityLevel.extreme => AppTheme.bullish,
      };

  @override
  Widget build(BuildContext context) {
    if (report.atr == 0) {
      return const SizedBox.shrink();
    }
    final c = _color();
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart,
                  size: 16, color: AppTheme.accent),
              const SizedBox(width: 6),
              const Text(
                '波動度分析',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  report.level.label,
                  style: TextStyle(
                    color: c,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _metric(
                  'ATR(14)',
                  Fmt.price(report.atr),
                  '${report.atrPctOfClose.toStringAsFixed(2)}% 收盤價',
                ),
              ),
              Container(
                  width: 1,
                  height: 36,
                  color: AppTheme.borderColor),
              Expanded(
                child: _metric(
                  '年化波動率',
                  '${report.historicalVolAnnual.toStringAsFixed(1)}%',
                  '日波動標準差 × √252',
                ),
              ),
              Container(
                  width: 1,
                  height: 36,
                  color: AppTheme.borderColor),
              Expanded(
                child: _metric(
                  '布林寬度',
                  '${report.bandwidthPct.toStringAsFixed(2)}%',
                  report.bandwidthPct < 6 ? '收斂中' : '正常',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: AppTheme.bgSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      '預期波動區間 (±2 ATR)',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 11),
                    ),
                    const Spacer(),
                    Text(
                      Fmt.price(report.expectedLow),
                      style: TextStyle(
                        color: AppTheme.bearish,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '〜',
                        style:
                            TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                    Text(
                      Fmt.price(report.expectedHigh),
                      style: TextStyle(
                        color: AppTheme.bullish,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  report.level.advice,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value, String sub) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 10),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 9),
          ),
        ],
      ),
    );
  }
}
