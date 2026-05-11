import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/price_alert.dart';
import '../../data/providers/price_alert_provider.dart';

Future<void> showPriceAlertSheet(
  BuildContext context, {
  required String symbol,
  required String name,
  required double currentPrice,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.bgPrimary,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _PriceAlertSheet(
      symbol: symbol,
      name: name,
      currentPrice: currentPrice,
    ),
  );
}

class _PriceAlertSheet extends ConsumerStatefulWidget {
  final String symbol;
  final String name;
  final double currentPrice;
  const _PriceAlertSheet({
    required this.symbol,
    required this.name,
    required this.currentPrice,
  });

  @override
  ConsumerState<_PriceAlertSheet> createState() => _PriceAlertSheetState();
}

class _PriceAlertSheetState extends ConsumerState<_PriceAlertSheet> {
  AlertDirection _direction = AlertDirection.above;
  final _priceCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 預填當前價的 ±3%
    _priceCtrl.text = (widget.currentPrice * 1.03).toStringAsFixed(2);
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    super.dispose();
  }

  void _updateDefault(AlertDirection d) {
    final factor = d == AlertDirection.above ? 1.03 : 0.97;
    _priceCtrl.text = (widget.currentPrice * factor).toStringAsFixed(2);
    setState(() => _direction = d);
  }

  void _save() {
    final price = double.tryParse(_priceCtrl.text);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請輸入有效價格')),
      );
      return;
    }
    ref.read(priceAlertsProvider.notifier).addAlert(
          symbol: widget.symbol,
          name: widget.name,
          direction: _direction,
          price: price,
        );
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已建立警示：${widget.symbol} '
            '${_direction == AlertDirection.above ? '高於' : '低於'} '
            '${Fmt.price(price)}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final existing =
        ref.watch(priceAlertsProvider).where((a) => a.symbol == widget.symbol).toList();
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
              '${widget.name} (${widget.symbol}) 價格警示',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '目前 ${Fmt.price(widget.currentPrice)} 元',
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 11),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('高於'),
                    selected: _direction == AlertDirection.above,
                    onSelected: (_) => _updateDefault(AlertDirection.above),
                    backgroundColor: AppTheme.bgSurface,
                    selectedColor:
                        AppTheme.bullish.withValues(alpha: 0.18),
                    labelStyle: TextStyle(
                      color: _direction == AlertDirection.above
                          ? AppTheme.bullish
                          : AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                    side: BorderSide(
                      color: _direction == AlertDirection.above
                          ? AppTheme.bullish
                          : AppTheme.borderColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('低於'),
                    selected: _direction == AlertDirection.below,
                    onSelected: (_) => _updateDefault(AlertDirection.below),
                    backgroundColor: AppTheme.bgSurface,
                    selectedColor:
                        AppTheme.bearish.withValues(alpha: 0.18),
                    labelStyle: TextStyle(
                      color: _direction == AlertDirection.below
                          ? AppTheme.bearish
                          : AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                    side: BorderSide(
                      color: _direction == AlertDirection.below
                          ? AppTheme.bearish
                          : AppTheme.borderColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _priceCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: InputDecoration(
                labelText: '觸發價格',
                suffixText: '元',
                prefixIcon: const Icon(Icons.attach_money,
                    color: AppTheme.textSecondary),
                helperText: '價格 ${_direction == AlertDirection.above ? '漲到' : '跌到'} '
                    '${_priceCtrl.text} 元時跳出通知',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.notification_add_outlined),
                label: const Text('建立警示'),
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            if (existing.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Divider(color: AppTheme.borderColor),
              const SizedBox(height: 10),
              const Text(
                '已建立的警示',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              ...existing.map((a) => _AlertTile(alert: a)),
            ],
          ],
        ),
      ),
    );
  }
}

class _AlertTile extends ConsumerWidget {
  final PriceAlert alert;
  const _AlertTile({required this.alert});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(
        alert.direction == AlertDirection.above
            ? Icons.arrow_upward
            : Icons.arrow_downward,
        color: alert.direction == AlertDirection.above
            ? AppTheme.bullish
            : AppTheme.bearish,
        size: 18,
      ),
      title: Text(
        '${alert.directionLabel} ${Fmt.price(alert.price)} 元',
        style: TextStyle(
          color: alert.enabled
              ? AppTheme.textPrimary
              : AppTheme.textSecondary,
          fontSize: 13,
          decoration: alert.enabled ? null : TextDecoration.lineThrough,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            value: alert.enabled,
            onChanged: (_) =>
                ref.read(priceAlertsProvider.notifier).toggle(alert.id),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            onPressed: () =>
                ref.read(priceAlertsProvider.notifier).remove(alert.id),
          ),
        ],
      ),
    );
  }
}
