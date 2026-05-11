import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/network_progress_bar.dart';
import '../../data/models/ticker.dart';
import '../../data/providers/providers.dart';

/// 加入自選股的搜尋 sheet — 支援用代號或名稱搜尋。
Future<void> showAddStockSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.bgPrimary,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => const _AddStockSheet(),
  );
}

class _AddStockSheet extends ConsumerStatefulWidget {
  const _AddStockSheet();

  @override
  ConsumerState<_AddStockSheet> createState() => _AddStockSheetState();
}

class _AddStockSheetState extends ConsumerState<_AddStockSheet> {
  final _ctrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(tickerCatalogProvider);
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.78,
        child: Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '加入自選股',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ),
            const NetworkProgressBar(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, size: 20),
                  hintText: '輸入代號或名稱（例如 2330 或 台積電）',
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _ctrl.clear();
                            setState(() => _query = '');
                          },
                        ),
                ),
              ),
            ),
            Expanded(
              child: catalog.when(
                data: (all) => _ResultList(query: _query, all: all),
                loading: () => const _LoadingHint(),
                error: (e, _) => _ErrorHint(message: e.toString(), onRetry: () {
                  ref.invalidate(tickerCatalogProvider);
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingHint extends StatelessWidget {
  const _LoadingHint();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppTheme.accent),
          SizedBox(height: 12),
          Text(
            '載入全市場代號中…',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ErrorHint extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorHint({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off,
                color: AppTheme.textSecondary, size: 32),
            const SizedBox(height: 12),
            Text(
              '取得代號清單失敗\n$message',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('重試'),
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultList extends ConsumerWidget {
  final String query;
  final List<Ticker> all;
  const _ResultList({required this.query, required this.all});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (query.trim().isEmpty) {
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          const SizedBox(height: 8),
          Text(
            '已載入 ${all.length} 檔，輸入關鍵字即時搜尋',
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),
          const _SectionLabel('熱門'),
          for (final s in _hot)
            if (all.any((t) => t.symbol == s.$1))
              _TickerRow(
                ticker: all.firstWhere((t) => t.symbol == s.$1),
                onTap: (t) => _onTap(context, ref, t),
              ),
        ],
      );
    }

    final service = ref.read(tickerCatalogServiceProvider);
    final results = service.search(query, limit: 80);
    if (results.isEmpty) {
      return const Center(
        child: Text('查無符合代號或名稱的股票',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: results.length,
      itemBuilder: (_, i) => _TickerRow(
        ticker: results[i],
        onTap: (t) => _onTap(context, ref, t),
      ),
    );
  }

  static const List<(String, String)> _hot = [
    ('2330', '台積電'),
    ('2317', '鴻海'),
    ('2454', '聯發科'),
    ('2308', '台達電'),
    ('0050', '元大台灣50'),
    ('0056', '元大高股息'),
  ];

  void _onTap(BuildContext context, WidgetRef ref, Ticker t) {
    final list = ref.read(watchlistProvider);
    final exists = list.any((w) => w.symbol == t.symbol);
    if (exists) {
      // 已存在 → 移除（toggle）
      ref.read(watchlistProvider.notifier).remove(t.symbol);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已從自選移除「${t.name}」'),
          duration: const Duration(milliseconds: 1200),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ref.read(watchlistProvider.notifier).add(t.symbol, t.name);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已加入「${t.name} (${t.symbol})」'),
          duration: const Duration(milliseconds: 1200),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    // 不關閉 sheet，讓使用者繼續選
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 0, 6),
        child: Text(
          text,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}

class _TickerRow extends ConsumerWidget {
  final Ticker ticker;
  final void Function(Ticker) onTap;
  const _TickerRow({required this.ticker, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inList = ref.watch(watchlistProvider)
        .any((w) => w.symbol == ticker.symbol);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap(ticker),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 64,
                child: Text(
                  ticker.symbol,
                  style: const TextStyle(
                    color: AppTheme.accent,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  ticker.name,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.bgSurface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Text(
                  ticker.market,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                inList ? Icons.check_circle : Icons.add_circle_outline,
                color: inList ? AppTheme.bearish : AppTheme.accent,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
