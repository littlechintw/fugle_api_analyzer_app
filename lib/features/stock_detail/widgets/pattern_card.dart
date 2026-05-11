import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/candle.dart';
import '../../../indicators/pattern_recognition.dart';

class PatternCard extends StatelessWidget {
  final List<Candle> candles;
  const PatternCard({super.key, required this.candles});

  static final _dateFmt = DateFormat('MM/dd');

  @override
  Widget build(BuildContext context) {
    final patterns = PatternRecognition.detect(candles);
    if (patterns.isEmpty) return const SizedBox.shrink();
    // 反序，最新型態在最上面
    final sorted = patterns.toList()..sort((a, b) => b.index.compareTo(a.index));
    final show = sorted.take(6).toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
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
              const Icon(Icons.auto_awesome,
                  size: 14, color: AppTheme.accent),
              const SizedBox(width: 4),
              const Text(
                'K 線型態偵測',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              Text(
                '近 30 日 ${patterns.length} 個訊號',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...show.map((p) => _row(p)),
        ],
      ),
    );
  }

  Widget _row(CandlePattern p) {
    final color = switch (p.bias) {
      PatternBias.bullish => AppTheme.bullish,
      PatternBias.bearish => AppTheme.bearish,
      PatternBias.neutral => AppTheme.neutral,
    };
    final date = p.index < candles.length
        ? _dateFmt.format(candles[p.index].date)
        : '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(p.emoji,
                style: const TextStyle(fontSize: 16)),
          ),
          SizedBox(
            width: 46,
            child: Text(
              date,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              p.name,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              p.description,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
