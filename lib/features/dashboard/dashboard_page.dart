import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/disclaimer_dialog.dart';
import '../../core/widgets/network_progress_bar.dart';
import '../../data/providers/providers.dart';
import '../market/market_page.dart';
import '../search/add_stock_sheet.dart';
import '../settings/settings_page.dart';
import '../stock_detail/stock_detail_page.dart';
import 'widgets/stock_card.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  void initState() {
    super.initState();
    // 第一次開啟跳免責 dialog (內部會檢查是否已同意)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ensureDisclaimerShown(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final raw = ref.watch(watchlistProvider);
    final sort = ref.watch(watchlistSortProvider);
    final tokenAsync = ref.watch(apiTokenProvider);
    final list = _sortWatchlist(ref, raw, sort);

    final busy = ref.watch(networkActivityProvider) > 0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('股市技術分析'),
        actions: [
          IconButton(
            tooltip: '重新整理',
            icon: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.accent,
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: busy
                ? null
                : () {
                    for (final w in list) {
                      ref.invalidate(quoteProvider(w.symbol));
                      ref.invalidate(candlesProvider(w.symbol));
                    }
                  },
          ),
          IconButton(
            tooltip: '市場熱度',
            icon: const Icon(Icons.trending_up),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MarketPage()),
            ),
          ),
          IconButton(
            tooltip: '設定',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(2.5),
          child: NetworkProgressBar(),
        ),
      ),
      body: Column(
        children: [
          tokenAsync.when(
            data: (s) => s.hasToken
                ? const SizedBox.shrink()
                : const _TokenBanner(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                const Text(
                  '自選股',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                Text(
                  '${list.length} 檔',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final m in WatchlistSort.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(m.label,
                          style: const TextStyle(fontSize: 12)),
                      selected: sort == m,
                      onSelected: (_) =>
                          ref.read(watchlistSortProvider.notifier).set(m),
                      backgroundColor: AppTheme.bgSurface,
                      selectedColor:
                          AppTheme.accent.withValues(alpha: 0.20),
                      labelStyle: TextStyle(
                        color: sort == m
                            ? AppTheme.accent
                            : AppTheme.textSecondary,
                      ),
                      side: BorderSide(
                        color: sort == m
                            ? AppTheme.accent
                            : AppTheme.borderColor,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? const Center(
                    child: Text(
                      '尚未加入任何自選股',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final item = list[i];
                      return StockCard(
                        item: item,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => StockDetailPage(
                              symbol: item.symbol,
                              name: item.name,
                            ),
                          ),
                        ),
                        onLongPress: () => _confirmRemove(context, ref, item.symbol, item.name),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddStockSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('加入自選'),
      ),
    );
  }

  /// 依排序模式排列自選股；對需要報價的排序模式 (changeAsc/Desc) 會讀取
  /// quoteProvider 已快取的值 (StockRepository.cachedQuote)。
  List _sortWatchlist(WidgetRef ref, List raw, WatchlistSort sort) {
    final out = [...raw];
    final repo = ref.read(stockRepositoryProvider);
    switch (sort) {
      case WatchlistSort.custom:
        break;
      case WatchlistSort.symbolAsc:
        out.sort((a, b) => a.symbol.compareTo(b.symbol));
        break;
      case WatchlistSort.nameAsc:
        out.sort((a, b) => a.name.compareTo(b.name));
        break;
      case WatchlistSort.changeDesc:
      case WatchlistSort.changeAsc:
        double cp(dynamic w) =>
            repo.cachedQuote(w.symbol)?.changePercent ?? 0;
        out.sort((a, b) => sort == WatchlistSort.changeDesc
            ? cp(b).compareTo(cp(a))
            : cp(a).compareTo(cp(b)));
        break;
    }
    return out;
  }

  Future<void> _confirmRemove(
      BuildContext context, WidgetRef ref, String symbol, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('移除自選股'),
        content: Text('要從自選股移除「$name ($symbol)」嗎？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('移除')),
        ],
      ),
    );
    if (ok == true) {
      ref.read(watchlistProvider.notifier).remove(symbol);
    }
  }
}

class _TokenBanner extends StatelessWidget {
  const _TokenBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.accent.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppTheme.accent),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              '尚未設定 Fugle API Token，請前往設定頁填寫',
              style: TextStyle(fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
            child: const Text('前往設定'),
          ),
        ],
      ),
    );
  }
}
