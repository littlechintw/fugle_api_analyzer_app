import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/institutional_flow.dart';

class InstitutionalCard extends StatelessWidget {
  final InstitutionalSnapshot snapshot;
  const InstitutionalCard({super.key, required this.snapshot});

  static final _dateFmt = DateFormat('MM/dd');

  @override
  Widget build(BuildContext context) {
    final flows = snapshot.flows;
    if (flows.isEmpty && snapshot.isComplete) {
      return _empty();
    }
    if (flows.isEmpty) {
      // 還沒任何資料，但 stream 還在跑
      return _loadingHint();
    }
    final last = flows.last;
    final totalRecent = flows.fold<int>(0, (a, f) => a + f.total);
    final color = totalRecent > 0
        ? AppTheme.bullish
        : totalRecent < 0
            ? AppTheme.bearish
            : AppTheme.neutral;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance,
                  size: 16, color: AppTheme.accent),
              const SizedBox(width: 6),
              const Text(
                '三大法人買賣超',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              Text(
                '近 ${flows.length} 日合計 ${_signed(totalRecent)} 張',
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (!snapshot.isComplete) _progressBar(),
          const SizedBox(height: 12),
          // 標題列
          DefaultTextStyle(
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 10),
            child: Row(
              children: const [
                SizedBox(width: 44, child: Text('日期')),
                Expanded(
                    child: Text('外資', textAlign: TextAlign.end)),
                Expanded(
                    child: Text('投信', textAlign: TextAlign.end)),
                Expanded(
                    child: Text('自營', textAlign: TextAlign.end)),
                Expanded(
                    child: Text('合計', textAlign: TextAlign.end)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          ...flows.reversed.map((f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    SizedBox(
                      width: 44,
                      child: Text(
                        _dateFmt.format(f.date),
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(child: _cell(f.foreign)),
                    Expanded(child: _cell(f.trust)),
                    Expanded(child: _cell(f.dealer)),
                    Expanded(
                        child: _cell(f.total, bold: true)),
                  ],
                ),
              )),
          const SizedBox(height: 8),
          if (last.foreign > 0 && last.trust > 0)
            _hintTag(
              icon: '🎯',
              text: '外資投信同步買超，籌碼面偏多',
              color: AppTheme.bullish,
            )
          else if (last.foreign < 0 && last.trust < 0)
            _hintTag(
              icon: '⚠️',
              text: '外資投信同步賣超，籌碼面偏空',
              color: AppTheme.bearish,
            )
          else
            _hintTag(
              icon: '⚖️',
              text: '三大法人方向不一致',
              color: AppTheme.neutral,
            ),
          if (snapshot.isComplete && flows.length < snapshot.total) ...[
            const SizedBox(height: 8),
            const Text(
              '※ 今日資料 TWSE 約 17:00 後公告，下拉重新整理可取得最新',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _cell(int v, {bool bold = false}) => Text(
        _signed(v),
        textAlign: TextAlign.end,
        style: TextStyle(
          color: v > 0
              ? AppTheme.bullish
              : v < 0
                  ? AppTheme.bearish
                  : AppTheme.textSecondary,
          fontSize: 12,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      );

  Widget _hintTag(
          {required String icon,
          required String text,
          required Color color}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );

  Widget _progressBar() {
    final pct = snapshot.total == 0 ? 0.0 : snapshot.loaded / snapshot.total;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: AppTheme.accent,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '正在載入買賣超…',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 3,
              backgroundColor: AppTheme.bgSurface,
              color: AppTheme.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingHint() => Container(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.account_balance,
                    size: 16, color: AppTheme.accent),
                SizedBox(width: 6),
                Text(
                  '三大法人買賣超',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            _progressBar(),
          ],
        ),
      );

  Widget _empty() => Container(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: const Row(
          children: [
            Icon(Icons.account_balance,
                size: 16, color: AppTheme.textSecondary),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '三大法人資料載入中或查無資料 (上櫃股票暫不支援)',
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12),
              ),
            ),
          ],
        ),
      );

  static String _fmt(int v) {
    final s = NumberFormat('#,##0').format(v.abs());
    return s;
  }

  /// 帶符號格式：正值 +1,234，負值 -1,234，零 0
  static String _signed(int v) {
    if (v == 0) return '0';
    return NumberFormat('+#,##0;-#,##0').format(v);
  }
}
