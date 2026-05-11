import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/dividend.dart';

class DividendCard extends StatelessWidget {
  final List<Dividend> dividends;
  final double currentPrice;
  const DividendCard({
    super.key,
    required this.dividends,
    required this.currentPrice,
  });

  static final _dateFmt = DateFormat('yyyy/MM/dd');
  static final _dateYM = DateFormat('yyyy');

  @override
  Widget build(BuildContext context) {
    if (dividends.isEmpty) return const SizedBox.shrink();

    // 找未來預告
    final upcoming = dividends.where((d) => d.isFuture).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final past = dividends.where((d) => !d.isFuture).take(8).toList();

    // 計算近一年現金股利合計與殖利率
    final oneYearAgo = DateTime.now().subtract(const Duration(days: 365));
    final lastYearCash = past
        .where((d) => d.date.isAfter(oneYearAgo))
        .fold<double>(0, (a, d) => a + d.cashDividend);
    final yieldNow = currentPrice > 0
        ? (lastYearCash / currentPrice * 100)
        : 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
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
              const Icon(Icons.payments_outlined,
                  size: 14, color: AppTheme.accent),
              const SizedBox(width: 4),
              const Text(
                '除權息',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              if (currentPrice > 0)
                Text(
                  '殖利率 ${yieldNow.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: yieldNow >= 4
                        ? AppTheme.bullish
                        : AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (upcoming.isNotEmpty) _upcomingBanner(upcoming.first),
          if (upcoming.isNotEmpty) const SizedBox(height: 10),
          // 過去歷史表格
          if (past.isEmpty)
            const Text(
              '近 5 年內無除權息紀錄',
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 11),
            )
          else ...[
            DefaultTextStyle(
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 10),
              child: Row(
                children: const [
                  SizedBox(width: 78, child: Text('除權息日')),
                  Expanded(
                      child: Text('現金股利', textAlign: TextAlign.end)),
                  Expanded(
                      child: Text('股票配股', textAlign: TextAlign.end)),
                  Expanded(
                      child: Text('類別', textAlign: TextAlign.end)),
                ],
              ),
            ),
            const SizedBox(height: 4),
            ...past.map((d) => _row(d)),
          ],
        ],
      ),
    );
  }

  Widget _upcomingBanner(Dividend d) {
    final days = d.date.difference(DateTime.now()).inDays;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: AppTheme.accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_outlined,
              size: 14, color: AppTheme.accent),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '下次除權息：${_dateFmt.format(d.date)} (還有 $days 天)',
                  style: const TextStyle(
                    color: AppTheme.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '配發現金 ${d.cashDividend.toStringAsFixed(3)} 元'
                  '${d.stockDividendShares > 0 ? '、配股 ${d.stockDividendShares.toStringAsFixed(0)} 股/仟股' : ''}',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(Dividend d) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 78,
            child: Text(
              _dateFmt.format(d.date),
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: Text(
              d.cashDividend > 0
                  ? d.cashDividend.toStringAsFixed(3)
                  : '—',
              textAlign: TextAlign.end,
              style: TextStyle(
                color: d.cashDividend > 0
                    ? AppTheme.textPrimary
                    : AppTheme.textSecondary,
                fontSize: 11,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Expanded(
            child: Text(
              d.stockDividendShares > 0
                  ? Fmt.integer(d.stockDividendShares)
                  : '—',
              textAlign: TextAlign.end,
              style: TextStyle(
                color: d.stockDividendShares > 0
                    ? AppTheme.textPrimary
                    : AppTheme.textSecondary,
                fontSize: 11,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Expanded(
            child: Text(
              d.dividendType.isEmpty ? '—' : d.dividendType,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
