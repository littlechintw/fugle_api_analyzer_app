import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/fundamental.dart';

class FundamentalCard extends StatelessWidget {
  final FundamentalSnapshot snapshot;
  const FundamentalCard({super.key, required this.snapshot});

  @override
  Widget build(BuildContext context) {
    if (snapshot.isEmpty) return const SizedBox.shrink();
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
              const Icon(Icons.fact_check_outlined,
                  size: 14, color: AppTheme.accent),
              const SizedBox(width: 4),
              const Text(
                '基本面',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              if (snapshot.dividendYear != null)
                Text(
                  '股利年度 ${snapshot.dividendYear}',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 10),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _metric(
                  '本益比 PE',
                  snapshot.peRatio,
                  suffix: '倍',
                  hint: snapshot.peRatio == null
                      ? '無資料'
                      : snapshot.peRatio! > 30
                          ? '偏高'
                          : snapshot.peRatio! < 10
                              ? '偏低'
                              : '合理',
                ),
              ),
              _divider(),
              Expanded(
                child: _metric(
                  '股價淨值比 PB',
                  snapshot.pbRatio,
                  suffix: '倍',
                  hint: snapshot.pbRatio == null
                      ? '無資料'
                      : snapshot.pbRatio! > 3
                          ? '偏高'
                          : snapshot.pbRatio! < 1
                              ? '低於淨值'
                              : '合理',
                ),
              ),
              _divider(),
              Expanded(
                child: _metric(
                  '殖利率',
                  snapshot.dividendYield,
                  suffix: '%',
                  highlightHigh: true,
                  hint: snapshot.dividendYield == null
                      ? '無資料'
                      : snapshot.dividendYield! >= 5
                          ? '高股息'
                          : snapshot.dividendYield! >= 3
                              ? '不錯'
                              : '一般',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 36,
        color: AppTheme.borderColor,
      );

  Widget _metric(
    String label,
    double? value, {
    String suffix = '',
    String? hint,
    bool highlightHigh = false,
  }) {
    final isAvailable = value != null;
    final color = isAvailable
        ? (highlightHigh && value >= 5
            ? AppTheme.bullish
            : AppTheme.textPrimary)
        : AppTheme.textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 10),
          ),
          const SizedBox(height: 4),
          Text(
            isAvailable ? '${value.toStringAsFixed(2)}$suffix' : '—',
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 2),
            Text(
              hint,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }
}
