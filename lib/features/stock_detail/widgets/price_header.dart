import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/stock_quote.dart';

class PriceHeader extends StatelessWidget {
  final StockQuote quote;
  const PriceHeader({super.key, required this.quote});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.trendColor(quote.change);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: const BoxDecoration(
        color: AppTheme.bgSurface,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Fmt.price(quote.lastPrice),
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '${Fmt.signed(quote.change)}  ${Fmt.percent(quote.changePercent)}',
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 18,
            runSpacing: 8,
            children: [
              _kv('開', Fmt.price(quote.openPrice)),
              _kv('高', Fmt.price(quote.highPrice)),
              _kv('低', Fmt.price(quote.lowPrice)),
              _kv('昨收', Fmt.price(quote.previousClose)),
              _kv('成交量', Fmt.volume(quote.volume)),
              _kv('更新', Fmt.datetime(quote.updatedAt)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$k ',
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 12)),
        Text(v,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            )),
      ],
    );
  }
}
