import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/order_book.dart';

class OrderBookCard extends StatelessWidget {
  final OrderBookSnapshot book;
  const OrderBookCard({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    final bids = book.bids.take(5).toList();
    final asks = book.asks.take(5).toList();
    // 補滿 5 檔
    while (bids.length < 5) {
      bids.add(const PriceLevel(price: 0, size: 0));
    }
    while (asks.length < 5) {
      asks.add(const PriceLevel(price: 0, size: 0));
    }
    final maxSize = [
      ...bids.map((e) => e.size),
      ...asks.map((e) => e.size),
    ].fold<int>(0, (a, b) => b > a ? b : a);

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
              Icon(Icons.swap_horiz, size: 14, color: AppTheme.accent),
              SizedBox(width: 4),
              Text(
                '五檔買賣 / 內外盤',
                style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 內外盤比
          _BidAskBar(snapshot: book),
          const SizedBox(height: 12),
          // 五檔表格
          Row(
            children: [
              Expanded(child: _side(bids, maxSize, isBid: true)),
              Container(
                width: 1,
                height: 100,
                color: AppTheme.borderColor,
              ),
              Expanded(child: _side(asks, maxSize, isBid: false)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _side(List<PriceLevel> rows, int maxSize, {required bool isBid}) {
    final color = isBid ? AppTheme.bullish : AppTheme.bearish;
    final label = isBid ? '委買' : '委賣';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Row(
            mainAxisAlignment: isBid
                ? MainAxisAlignment.start
                : MainAxisAlignment.end,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        ...rows.asMap().entries.map((e) {
          final lvl = e.value;
          final pct = maxSize == 0 ? 0.0 : lvl.size / maxSize;
          return _row(lvl, pct, color, isBid);
        }),
      ],
    );
  }

  Widget _row(PriceLevel lvl, double pct, Color color, bool isBid) {
    final showEmpty = lvl.size == 0;
    return SizedBox(
      height: 18,
      child: Stack(
        children: [
          if (!showEmpty)
            Align(
              alignment:
                  isBid ? Alignment.centerRight : Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: pct.clamp(0.02, 1.0),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 1),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: isBid
                  ? MainAxisAlignment.spaceBetween
                  : MainAxisAlignment.spaceBetween,
              children: isBid
                  ? [
                      Text(
                        showEmpty ? '—' : '${lvl.size}',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        showEmpty ? '' : Fmt.price(lvl.price),
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ]
                  : [
                      Text(
                        showEmpty ? '' : Fmt.price(lvl.price),
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        showEmpty ? '—' : '${lvl.size}',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BidAskBar extends StatelessWidget {
  final OrderBookSnapshot snapshot;
  const _BidAskBar({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final bidPct = snapshot.bidRatio;
    final askPct = snapshot.askRatio;
    final dominant = bidPct > askPct ? '內盤' : '外盤';
    final color = bidPct > askPct ? AppTheme.bearish : AppTheme.bullish;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              '內盤 ${(bidPct * 100).toStringAsFixed(1)}%',
              style: const TextStyle(
                color: AppTheme.bearish,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '$dominant 主動',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              '外盤 ${(askPct * 100).toStringAsFixed(1)}%',
              style: const TextStyle(
                color: AppTheme.bullish,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(
            height: 6,
            child: Row(
              children: [
                Expanded(
                  flex: (bidPct * 1000).round().clamp(1, 1000),
                  child: Container(color: AppTheme.bearish),
                ),
                Expanded(
                  flex: (askPct * 1000).round().clamp(1, 1000),
                  child: Container(color: AppTheme.bullish),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
