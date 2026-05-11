import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/ticker.dart';
import '../../../data/providers/providers.dart';

/// 自選股全空時的引導畫面
class EmptyWatchlistView extends ConsumerWidget {
  final VoidCallback onAddTap;
  const EmptyWatchlistView({super.key, required this.onAddTap});

  static const List<(String, String)> _hot = [
    ('2330', '台積電'),
    ('2317', '鴻海'),
    ('2454', '聯發科'),
    ('2308', '台達電'),
    ('0050', '元大台灣50'),
    ('0056', '元大高股息'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 100),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.candlestick_chart_outlined,
                size: 44,
                color: AppTheme.accent,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              '開始追蹤您關注的股票',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '加入自選後可一鍵查看即時報價、K 線、\n技術指標與三大法人籌碼',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAddTap,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('搜尋並加入第一檔'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 36),
            const Text(
              '或從熱門股票開始',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final s in _hot)
                  ActionChip(
                    label: Text('${s.$2} ${s.$1}'),
                    onPressed: () {
                      ref
                          .read(watchlistProvider.notifier)
                          .add(s.$1, s.$2);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('已加入 ${s.$2} (${s.$1})'),
                          duration: const Duration(milliseconds: 1200),
                        ),
                      );
                    },
                    backgroundColor: AppTheme.bgSurface,
                    side: const BorderSide(color: AppTheme.borderColor),
                    labelStyle: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 把 Ticker 用作 ActionChip 顯示用 (預留給 catalog 載入完成後使用)
extension TickerToChip on Ticker {
  String chipLabel() => '$name $symbol';
}
