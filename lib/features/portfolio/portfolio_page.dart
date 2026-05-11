import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/network_progress_bar.dart';
import '../../data/models/holding.dart';
import '../../data/providers/providers.dart';
import '../stock_detail/stock_detail_page.dart';

class PortfolioPage extends ConsumerWidget {
  const PortfolioPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holdings = ref.watch(holdingsProvider);
    final repo = ref.watch(stockRepositoryProvider);

    // 加總
    double totalCost = 0;
    double totalValue = 0;
    final rows = <_HoldingRow>[];
    for (final h in holdings) {
      final q = repo.cachedQuote(h.symbol);
      final price = q?.lastPrice ?? h.avgCost;
      totalCost += h.costBasis;
      totalValue += h.marketValue(price);
      rows.add(_HoldingRow(holding: h, currentPrice: price));
    }
    final totalPnL = totalValue - totalCost;
    final totalPct = totalCost == 0 ? 0.0 : totalPnL / totalCost * 100;

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的持倉'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(2.5),
          child: NetworkProgressBar(),
        ),
      ),
      body: holdings.isEmpty
          ? const _EmptyPortfolio()
          : Column(
              children: [
                _SummaryHeader(
                  totalCost: totalCost,
                  totalValue: totalValue,
                  totalPnL: totalPnL,
                  totalPct: totalPct,
                  count: holdings.length,
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                    itemCount: rows.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => rows[i],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('新增 / 編輯'),
      ),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgPrimary,
      builder: (_) => const _HoldingFormSheet(),
    );
  }
}

class _EmptyPortfolio extends StatelessWidget {
  const _EmptyPortfolio();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.account_balance_wallet,
                  size: 38, color: AppTheme.accent),
            ),
            const SizedBox(height: 16),
            const Text(
              '記錄您的持股',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '輸入股票代號、股數、成本價，\nApp 會自動計算未實現損益。',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '※ 純本機儲存，不接券商 API',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  final double totalCost;
  final double totalValue;
  final double totalPnL;
  final double totalPct;
  final int count;
  const _SummaryHeader({
    required this.totalCost,
    required this.totalValue,
    required this.totalPnL,
    required this.totalPct,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.trendColor(totalPnL);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: const BoxDecoration(
        color: AppTheme.bgSurface,
        border:
            Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '總市值',
            style: TextStyle(
                color: AppTheme.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            Fmt.price(totalValue),
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '${totalPnL >= 0 ? '+' : ''}${Fmt.price(totalPnL)} 元',
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${totalPct >= 0 ? '+' : ''}${totalPct.toStringAsFixed(2)}%)',
                style: TextStyle(color: color, fontSize: 12),
              ),
              const Spacer(),
              Text(
                '$count 檔持股',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '成本 ${Fmt.price(totalCost)} 元',
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _HoldingRow extends ConsumerWidget {
  final Holding holding;
  final double currentPrice;
  const _HoldingRow({required this.holding, required this.currentPrice});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pnl = holding.unrealizedPnL(currentPrice);
    final pct = holding.unrealizedPct(currentPrice);
    final color = AppTheme.trendColor(pnl);
    return Card(
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => StockDetailPage(
            symbol: holding.symbol,
            name: holding.name,
          ),
        )),
        onLongPress: () => _showEditSheet(context, ref, holding),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    holding.name,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    holding.symbol,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${pnl >= 0 ? '+' : ''}${Fmt.price(pnl)} 元',
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _label('股數', Fmt.integer(holding.quantity)),
                  const SizedBox(width: 16),
                  _label('成本', Fmt.price(holding.avgCost)),
                  const SizedBox(width: 16),
                  _label('現價', Fmt.price(currentPrice),
                      color: color),
                  const Spacer(),
                  Text(
                    '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String k, String v, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(k,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 11)),
        const SizedBox(width: 4),
        Text(
          v,
          style: TextStyle(
            color: color ?? AppTheme.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  void _showEditSheet(
      BuildContext context, WidgetRef ref, Holding holding) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgPrimary,
      builder: (_) => _HoldingFormSheet(initial: holding),
    );
  }
}

class _HoldingFormSheet extends ConsumerStatefulWidget {
  final Holding? initial;
  const _HoldingFormSheet({this.initial});

  @override
  ConsumerState<_HoldingFormSheet> createState() =>
      _HoldingFormSheetState();
}

class _HoldingFormSheetState extends ConsumerState<_HoldingFormSheet> {
  final _symbolCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _costCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final h = widget.initial;
    if (h != null) {
      _symbolCtrl.text = h.symbol;
      _nameCtrl.text = h.name;
      _qtyCtrl.text = h.quantity.toString();
      _costCtrl.text = h.avgCost.toString();
    }
  }

  @override
  void dispose() {
    _symbolCtrl.dispose();
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _costCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final symbol = _symbolCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    final qty = int.tryParse(_qtyCtrl.text);
    final cost = double.tryParse(_costCtrl.text);
    if (symbol.isEmpty || name.isEmpty || qty == null || cost == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請完整填寫所有欄位')),
      );
      return;
    }
    final h = Holding(
      symbol: symbol,
      name: name,
      quantity: qty,
      avgCost: cost,
      addedAt: widget.initial?.addedAt ?? DateTime.now(),
    );
    ref.read(holdingsProvider.notifier).upsert(h);
    Navigator.pop(context);
  }

  void _delete() {
    if (widget.initial == null) return;
    ref.read(holdingsProvider.notifier).remove(widget.initial!.symbol);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
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
            Text(
              isEdit ? '編輯持倉' : '新增持倉',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _symbolCtrl,
                    enabled: !isEdit,
                    decoration: const InputDecoration(
                      labelText: '代號',
                      hintText: '2330',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: '名稱',
                      hintText: '台積電',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _qtyCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: const InputDecoration(
                      labelText: '股數',
                      hintText: '1000',
                      suffixText: '股',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _costCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: '平均成本',
                      hintText: '600.5',
                      suffixText: '元',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (isEdit)
                  TextButton.icon(
                    icon: const Icon(Icons.delete_outline,
                        color: AppTheme.bullish),
                    label: const Text('刪除',
                        style:
                            TextStyle(color: AppTheme.bullish)),
                    onPressed: _delete,
                  ),
                const Spacer(),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save_outlined),
                  label: Text(isEdit ? '更新' : '建立'),
                  onPressed: _save,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
