import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_error.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/network_progress_bar.dart';
import '../../data/models/market_mover.dart';
import '../../data/providers/providers.dart';
import '../stock_detail/stock_detail_page.dart';

class MarketPage extends ConsumerStatefulWidget {
  const MarketPage({super.key});

  @override
  ConsumerState<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends ConsumerState<MarketPage> {
  MarketBoard _board = MarketBoard.tse;
  MoversKind _kind = MoversKind.gainers;

  @override
  Widget build(BuildContext context) {
    final args = (board: _board, kind: _kind);
    final dataAsync = ref.watch(marketMoversProvider(args));

    return Scaffold(
      appBar: AppBar(
        title: const Text('市場熱度'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '重新整理',
            onPressed: () =>
                ref.invalidate(marketMoversProvider(args)),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(2.5),
          child: NetworkProgressBar(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Row(
              children: [
                for (final b in MarketBoard.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(b.label,
                          style: const TextStyle(fontSize: 12)),
                      selected: _board == b,
                      onSelected: (_) => setState(() => _board = b),
                      backgroundColor: AppTheme.bgSurface,
                      selectedColor:
                          AppTheme.accent.withValues(alpha: 0.20),
                      labelStyle: TextStyle(
                        color: _board == b
                            ? AppTheme.accent
                            : AppTheme.textSecondary,
                      ),
                      side: BorderSide(
                        color: _board == b
                            ? AppTheme.accent
                            : AppTheme.borderColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final k in MoversKind.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(k.label,
                            style: const TextStyle(fontSize: 12)),
                        selected: _kind == k,
                        onSelected: (_) => setState(() => _kind = k),
                        backgroundColor: AppTheme.bgSurface,
                        selectedColor:
                            AppTheme.accent.withValues(alpha: 0.18),
                        labelStyle: TextStyle(
                          color: _kind == k
                              ? AppTheme.accent
                              : AppTheme.textSecondary,
                        ),
                        side: BorderSide(
                          color: _kind == k
                              ? AppTheme.accent
                              : AppTheme.borderColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // 表頭
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: DefaultTextStyle(
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 10),
              child: Row(
                children: [
                  const SizedBox(width: 60, child: Text('代號')),
                  const Expanded(child: Text('名稱')),
                  const SizedBox(
                      width: 70,
                      child: Text('收盤', textAlign: TextAlign.end)),
                  const SizedBox(
                      width: 70,
                      child: Text('漲跌幅', textAlign: TextAlign.end)),
                  SizedBox(
                    width: 80,
                    child: Text(
                      _kind == MoversKind.value ? '成交值' : '成交量',
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: dataAsync.when(
              data: (rows) => _list(rows),
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.accent),
              ),
              error: (e, _) => _ErrorView(message: e.userMessage),
            ),
          ),
        ],
      ),
    );
  }

  Widget _list(List<MarketMover> rows) {
    if (rows.isEmpty) {
      return const Center(
        child: Text('暫無資料',
            style: TextStyle(color: AppTheme.textSecondary)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: rows.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: AppTheme.borderColor),
      itemBuilder: (ctx, i) {
        final m = rows[i];
        return InkWell(
          onTap: () => Navigator.of(ctx).push(MaterialPageRoute(
            builder: (_) => StockDetailPage(symbol: m.symbol, name: m.name),
          )),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Text(
                    m.symbol,
                    style: const TextStyle(
                      color: AppTheme.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    m.name,
                    style: const TextStyle(
                        color: AppTheme.textPrimary, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  width: 70,
                  child: Text(
                    Fmt.price(m.closePrice),
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: AppTheme.trendColor(m.change),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                SizedBox(
                  width: 70,
                  child: Text(
                    '${m.changePercent >= 0 ? '+' : ''}'
                    '${m.changePercent.toStringAsFixed(2)}%',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: AppTheme.trendColor(m.change),
                      fontSize: 12,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    _kind == MoversKind.value
                        ? _shortValue(m.tradeValue)
                        : Fmt.integer(m.tradeVolume),
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _shortValue(double v) {
    if (v >= 1e8) return '${(v / 1e8).toStringAsFixed(2)} 億';
    if (v >= 1e4) return '${(v / 1e4).toStringAsFixed(0)} 萬';
    return Fmt.integer(v);
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                color: AppTheme.bullish, size: 32),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
