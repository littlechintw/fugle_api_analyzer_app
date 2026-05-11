import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/disclaimer_dialog.dart';
import '../../core/widgets/network_progress_bar.dart';
import '../../data/models/price_alert.dart';
import '../../data/models/watchlist_group.dart';
import '../../data/providers/watchlist_group_provider.dart';
import '../../data/providers/providers.dart';
import '../market/market_page.dart';
import '../search/add_stock_sheet.dart';
import '../settings/settings_page.dart';
import '../stock_detail/stock_detail_page.dart';
import 'widgets/empty_watchlist.dart';
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

  /// 檢查所有 enabled 警示是否被當前報價觸發，若是則彈 SnackBar 並標記
  void _checkPriceAlerts() {
    final alerts = ref.read(priceAlertsProvider);
    if (alerts.isEmpty) return;
    final repo = ref.read(stockRepositoryProvider);
    final notifier = ref.read(priceAlertsProvider.notifier);
    for (final a in alerts) {
      if (!a.enabled) continue;
      final q = repo.cachedQuote(a.symbol);
      if (q == null) continue;
      // 4 小時內已觸發過不重彈
      if (a.lastTriggeredAt != null &&
          DateTime.now().difference(a.lastTriggeredAt!) <
              const Duration(hours: 4)) {
        continue;
      }
      if (a.isTriggered(q.lastPrice)) {
        notifier.markTriggered(a.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🔔 ${a.name} (${a.symbol}) 已 ${a.directionLabel} '
              '${a.price.toStringAsFixed(2)} 元，現價 ${q.lastPrice.toStringAsFixed(2)}',
            ),
            backgroundColor: a.direction == AlertDirection.above
                ? AppTheme.bullish
                : AppTheme.bearish,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final raw = ref.watch(watchlistProvider);
    final sort = ref.watch(watchlistSortProvider);
    final tokenAsync = ref.watch(apiTokenProvider);
    final groups = ref.watch(watchlistGroupsProvider);
    final selectedGroup = ref.watch(selectedGroupProvider);
    final groupNotifier = ref.watch(watchlistGroupsProvider.notifier);

    // 依群組過濾
    final filtered = selectedGroup == WatchlistGroup.allGroupId
        ? raw
        : raw
            .where((w) =>
                groupNotifier.groupIdOf(w.symbol) == selectedGroup)
            .toList();
    final list = _sortWatchlist(ref, filtered, sort);

    final busy = ref.watch(networkActivityProvider) > 0;
    // 每次 build 結束後檢查價格警示
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkPriceAlerts();
    });
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
          if (groups.isNotEmpty) _groupTabs(ref, groups, selectedGroup),
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
                ? EmptyWatchlistView(
                    onAddTap: () => showAddStockSheet(context),
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
                        onLongPress: () => _showItemMenu(
                            context, ref, item.symbol, item.name),
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

  Widget _groupTabs(
      WidgetRef ref, List<WatchlistGroup> groups, String selected) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        children: [
          _groupChip(
            ref: ref,
            id: WatchlistGroup.allGroupId,
            label: '全部',
            selected: selected == WatchlistGroup.allGroupId,
          ),
          for (final g in groups)
            _groupChip(
              ref: ref,
              id: g.id,
              label: g.name,
              color: Color(g.colorValue),
              selected: selected == g.id,
            ),
          // 「+ 管理」按鈕
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: ActionChip(
              label: const Icon(Icons.tune, size: 14),
              onPressed: () => _showGroupManager(context, ref),
              backgroundColor: AppTheme.bgSurface,
              side: const BorderSide(color: AppTheme.borderColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _groupChip({
    required WidgetRef ref,
    required String id,
    required String label,
    Color? color,
    required bool selected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: selected,
        onSelected: (_) =>
            ref.read(selectedGroupProvider.notifier).state = id,
        backgroundColor: AppTheme.bgSurface,
        selectedColor: (color ?? AppTheme.accent).withValues(alpha: 0.20),
        labelStyle: TextStyle(
          color: selected ? (color ?? AppTheme.accent) : AppTheme.textSecondary,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(
          color: selected ? (color ?? AppTheme.accent) : AppTheme.borderColor,
        ),
      ),
    );
  }

  void _showItemMenu(
      BuildContext context, WidgetRef ref, String symbol, String name) {
    final groups = ref.read(watchlistGroupsProvider);
    final currentGroupId =
        ref.read(watchlistGroupsProvider.notifier).groupIdOf(symbol);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgPrimary,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  '$name ($symbol)',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  '目前群組：${groups.firstWhere(
                    (g) => g.id == currentGroupId,
                    orElse: () => const WatchlistGroup(
                        id: WatchlistGroup.allGroupId,
                        name: '全部',
                        sortOrder: 0,
                        colorValue: 0xFFFFB020),
                  ).name}',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.folder_open),
                title: const Text('移到「全部」(取消歸屬)'),
                trailing: currentGroupId == WatchlistGroup.allGroupId
                    ? const Icon(Icons.check, color: AppTheme.accent)
                    : null,
                onTap: () {
                  ref.read(watchlistGroupsProvider.notifier).assign(
                      symbol, WatchlistGroup.allGroupId);
                  Navigator.pop(ctx);
                },
              ),
              for (final g in groups)
                ListTile(
                  leading: Icon(Icons.folder, color: Color(g.colorValue)),
                  title: Text('移到「${g.name}」'),
                  trailing: currentGroupId == g.id
                      ? const Icon(Icons.check, color: AppTheme.accent)
                      : null,
                  onTap: () {
                    ref
                        .read(watchlistGroupsProvider.notifier)
                        .assign(symbol, g.id);
                    Navigator.pop(ctx);
                  },
                ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: AppTheme.bullish),
                title: const Text('從自選股移除',
                    style: TextStyle(color: AppTheme.bullish)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmRemove(context, ref, symbol, name);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGroupManager(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgPrimary,
      builder: (_) => const _GroupManagerSheet(),
    );
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

class _GroupManagerSheet extends ConsumerStatefulWidget {
  const _GroupManagerSheet();

  @override
  ConsumerState<_GroupManagerSheet> createState() =>
      _GroupManagerSheetState();
}

class _GroupManagerSheetState extends ConsumerState<_GroupManagerSheet> {
  final _ctrl = TextEditingController();
  static const _palette = [
    0xFFFFB020, // accent
    0xFFEF476F,
    0xFF06D6A0,
    0xFF118AB2,
    0xFF8E9DFF,
    0xFFFFD166,
  ];
  int _selectedColor = _palette.first;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _create() {
    final name = _ctrl.text.trim();
    if (name.isEmpty) return;
    ref.read(watchlistGroupsProvider.notifier).create(name, _selectedColor);
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(watchlistGroupsProvider);
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppTheme.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              '管理自選群組',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            // 既有群組
            if (groups.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  '尚未建立任何群組',
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12),
                ),
              )
            else
              ...groups.map((g) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading:
                        Icon(Icons.folder, color: Color(g.colorValue)),
                    title: Text(g.name),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: AppTheme.textSecondary),
                      onPressed: () => ref
                          .read(watchlistGroupsProvider.notifier)
                          .remove(g.id),
                    ),
                  )),
            const Divider(color: AppTheme.borderColor),
            const SizedBox(height: 8),
            const Text(
              '新增群組',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ctrl,
              decoration: const InputDecoration(
                labelText: '群組名稱',
                hintText: '例：長期持有、AI 概念',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final c in _palette)
                  GestureDetector(
                    onTap: () => setState(() => _selectedColor = c),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedColor == c
                              ? AppTheme.textPrimary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _create,
                icon: const Icon(Icons.add),
                label: const Text('建立群組'),
              ),
            ),
          ],
        ),
      ),
    );
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
