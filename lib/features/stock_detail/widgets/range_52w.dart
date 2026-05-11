import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/historical_stats.dart';

class Range52WCard extends StatelessWidget {
  final HistoricalStats stats;
  const Range52WCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final pos = stats.rangePosition();
    final fromHigh = stats.distanceFromHighPct();
    final fromLow = stats.distanceFromLowPct();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
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
              const Icon(Icons.swap_vert,
                  size: 14, color: AppTheme.accent),
              const SizedBox(width: 4),
              const Text(
                '52 週區間',
                style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                '相對位置 ${(pos * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                    color: AppTheme.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (ctx, c) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.bearish.withValues(alpha: 0.5),
                          AppTheme.accent.withValues(alpha: 0.7),
                          AppTheme.bullish.withValues(alpha: 0.5),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Positioned(
                    left: (c.maxWidth * pos).clamp(0, c.maxWidth - 8) - 4,
                    top: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppTheme.textPrimary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.bgPrimary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _label(
                '低 ${Fmt.price(stats.week52Low)}',
                '+${fromLow.toStringAsFixed(1)}%',
                AppTheme.bearish,
                Alignment.centerLeft,
              ),
              const Spacer(),
              _label(
                '高 ${Fmt.price(stats.week52High)}',
                '${fromHigh.toStringAsFixed(1)}%',
                AppTheme.bullish,
                Alignment.centerRight,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _label(String main, String sub, Color color, Alignment align) {
    return Column(
      crossAxisAlignment: align == Alignment.centerLeft
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          main,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '距收盤 $sub',
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
