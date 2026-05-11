import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/network_progress_bar.dart';
import '../../../data/models/watchlist_item.dart';
import '../../../data/providers/providers.dart';
import '../../../indicators/indicators.dart';
import 'sparkline.dart';

class StockCard extends ConsumerWidget {
  final WatchlistItem item;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const StockCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quoteAsync = ref.watch(quoteProvider(item.symbol));
    final candlesAsync = ref.watch(candlesProvider(item.symbol));

    return Card(
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              // 左：代號/名稱
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.symbol,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              // 中：Sparkline
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 36,
                  child: candlesAsync.when(
                    data: (c) {
                      if (c.isEmpty) {
                        return const Center(
                          child: Text(
                            '—',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        );
                      }
                      final last = c.length >= 30
                          ? c.sublist(c.length - 30)
                          : c;
                      final color = last.last.close >= last.first.close
                          ? AppTheme.bullish
                          : AppTheme.bearish;
                      return Sparkline(
                        values: normalizeCloses(last),
                        color: color,
                      );
                    },
                    loading: () => const _Shimmer(),
                    error: (_, __) => const Icon(
                      Icons.signal_wifi_off,
                      color: AppTheme.textSecondary,
                      size: 18,
                    ),
                  ),
                ),
              ),
              // 右：價格 + 漲跌
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    quoteAsync.when(
                      data: (q) => Text(
                        Fmt.price(q.lastPrice),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.trendColor(q.change),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      loading: () => const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: TinySpinner(size: 14),
                      ),
                      error: (_, __) => const Text(
                        'N/A',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 2),
                    quoteAsync.maybeWhen(
                      data: (q) => Text(
                        '${Fmt.signed(q.change)}  ${Fmt.percent(q.changePercent)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.trendColor(q.change),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Shimmer extends StatelessWidget {
  const _Shimmer();
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.bgSurface,
          borderRadius: BorderRadius.circular(4),
        ),
      );
}
