import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/price_volume.dart';
import '../../../data/providers/providers.dart';

class VolumesCard extends ConsumerWidget {
  final String symbol;
  const VolumesCard({super.key, required this.symbol});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(intradayVolumesProvider(symbol));
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
            children: const [
              Icon(Icons.bar_chart, size: 14, color: AppTheme.accent),
              SizedBox(width: 4),
              Text(
                '分價量 (籌碼分布)',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              Spacer(),
              Text(
                '紅=外盤主動 / 綠=內盤主動',
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 10),
          async.when(
            data: (rows) => _content(rows),
            loading: () => const SizedBox(
              height: 200,
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child:
                      CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (_, __) => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('尚無分價量資料',
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(List<PriceVolume> rows) {
    if (rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text('暫無資料',
            style: TextStyle(
                color: AppTheme.textSecondary, fontSize: 12)),
      );
    }
    // 找到累計成交最大者，作為長條基準
    final maxVol = rows.fold<int>(0, (a, b) => b.volume > a ? b.volume : a);
    // 找出最大成交價位 (主力集中區)
    final dominant = rows.reduce((a, b) => a.volume > b.volume ? a : b);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              const Text('🎯',
                  style: TextStyle(fontSize: 12)),
              const SizedBox(width: 6),
              Text(
                '主力價位 ${Fmt.price(dominant.price)} 元 '
                '(累計 ${Fmt.integer(dominant.volume)} 張)',
                style: const TextStyle(
                  color: AppTheme.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // 表頭
        Row(
          children: const [
            SizedBox(width: 60, child: Text('價格',
                textAlign: TextAlign.end,
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 10))),
            SizedBox(width: 8),
            Expanded(child: Text('成交量',
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 10))),
            SizedBox(width: 70, child: Text('量 (張)',
                textAlign: TextAlign.end,
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 10))),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 280,
          child: ListView.builder(
            itemCount: rows.length,
            itemBuilder: (_, i) => _row(rows[i], maxVol),
          ),
        ),
      ],
    );
  }

  Widget _row(PriceVolume p, int maxVol) {
    final ratio = maxVol == 0 ? 0.0 : p.volume / maxVol;
    final ask = p.volumeAtAsk;
    final bid = p.volumeAtBid;
    final total = ask + bid;
    final askPct = total == 0 ? 0.5 : ask / total;
    final bidPct = 1 - askPct;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              Fmt.price(p.price),
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: SizedBox(
                height: 12,
                child: Row(
                  children: [
                    Expanded(
                      flex: (ratio * 1000).round().clamp(1, 1000),
                      child: Row(
                        children: [
                          Expanded(
                            flex: (bidPct * 100).round().clamp(0, 100),
                            child: Container(color: AppTheme.bearish),
                          ),
                          Expanded(
                            flex: (askPct * 100).round().clamp(0, 100),
                            child: Container(color: AppTheme.bullish),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: ((1 - ratio) * 1000).round().clamp(0, 1000),
                      child: const SizedBox(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              Fmt.integer(p.volume),
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 11,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
