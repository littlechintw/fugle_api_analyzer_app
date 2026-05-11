import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/providers/providers.dart';

class TradesCard extends ConsumerWidget {
  final String symbol;
  const TradesCard({super.key, required this.symbol});

  static final _timeFmt = DateFormat('HH:mm:ss');
  static const _bigOrderThreshold = 100; // 張數，超過視為大單

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(intradayTradesProvider(symbol));
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
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
              const Icon(Icons.history, size: 14, color: AppTheme.accent),
              const SizedBox(width: 4),
              const Text(
                '逐筆成交 (近 100 筆)',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              const Text(
                '≥ 100 張為大單',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 16),
                color: AppTheme.textSecondary,
                onPressed: () =>
                    ref.invalidate(intradayTradesProvider(symbol)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          async.when(
            data: (trades) => _list(trades),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.accent,
                  ),
                ),
              ),
            ),
            error: (_, __) => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                '尚無逐筆資料',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _list(List trades) {
    if (trades.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text('尚無資料',
            style: TextStyle(
                color: AppTheme.textSecondary, fontSize: 12)),
      );
    }
    return Column(
      children: [
        // 表頭
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(width: 70, child: Text('時間',
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 10))),
              Expanded(child: Text('價格',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 10))),
              SizedBox(width: 60, child: Text('張數',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 10))),
              SizedBox(width: 36, child: Text('方向',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 10))),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.borderColor),
        SizedBox(
          height: 280,
          child: ListView.builder(
            itemCount: trades.length,
            itemBuilder: (_, i) => _row(trades[i]),
          ),
        ),
      ],
    );
  }

  Widget _row(dynamic t) {
    final isBig = t.size >= _bigOrderThreshold;
    final dirColor = t.isBuy
        ? AppTheme.bullish
        : t.isSell
            ? AppTheme.bearish
            : AppTheme.neutral;
    final bgColor = isBig
        ? (t.isBuy
            ? AppTheme.bullish.withValues(alpha: 0.08)
            : t.isSell
                ? AppTheme.bearish.withValues(alpha: 0.08)
                : Colors.transparent)
        : Colors.transparent;
    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              _timeFmt.format(t.time),
              style: TextStyle(
                color: isBig ? AppTheme.textPrimary : AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: isBig ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            child: Text(
              Fmt.price(t.price),
              textAlign: TextAlign.end,
              style: TextStyle(
                color: dirColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              t.size.toString(),
              textAlign: TextAlign.end,
              style: TextStyle(
                color: isBig ? dirColor : AppTheme.textPrimary,
                fontSize: 11,
                fontWeight: isBig ? FontWeight.w700 : FontWeight.normal,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          SizedBox(
            width: 36,
            child: Text(
              t.isBuy ? '↑ 買' : (t.isSell ? '↓ 賣' : '—'),
              textAlign: TextAlign.end,
              style: TextStyle(
                color: dirColor,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
