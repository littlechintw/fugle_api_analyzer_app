import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/capital_change.dart';

class CapitalChangesCard extends StatelessWidget {
  final List<CapitalChange> changes;
  const CapitalChangesCard({super.key, required this.changes});

  static final _dateFmt = DateFormat('yyyy/MM/dd');

  @override
  Widget build(BuildContext context) {
    if (changes.isEmpty) return const SizedBox.shrink();
    final upcoming = changes.where((c) => c.isFuture).toList();
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.event_busy, size: 14, color: AppTheme.accent),
              SizedBox(width: 4),
              Text(
                '股本變動 / 減資 / ETF 分割',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (upcoming.isNotEmpty) ...[
            ...upcoming.map((c) => _upcomingBanner(c)),
            if (changes.length > upcoming.length) const SizedBox(height: 6),
          ],
          ...changes.where((c) => !c.isFuture).take(5).map(_row),
        ],
      ),
    );
  }

  Widget _upcomingBanner(CapitalChange c) {
    final days = (c.haltDate ?? c.resumeDate!).difference(DateTime.now()).inDays;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: AppTheme.accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 14, color: AppTheme.accent),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '即將 ${c.displayLabel}'
                  '${days >= 0 ? ' (還有 $days 天)' : ''}',
                  style: const TextStyle(
                    color: AppTheme.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _detailText(c),
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(CapitalChange c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 78,
            child: Text(
              c.resumeDate != null ? _dateFmt.format(c.resumeDate!) : '—',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 11,
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
              c.displayLabel,
              style: const TextStyle(
                color: AppTheme.accent,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _detailText(c),
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _detailText(CapitalChange c) {
    final parts = <String>[];
    if (c.reason != null && c.reason!.isNotEmpty) {
      parts.add(c.reason!);
    }
    if (c.refundPerShare != null && c.refundPerShare! > 0) {
      parts.add('退還 ${c.refundPerShare!.toStringAsFixed(2)} 元/股');
    }
    if (c.splitType != null) {
      parts.add(c.splitType!);
    }
    if (c.previousClose != null && c.referencePrice != null) {
      parts.add(
          '${c.previousClose!.toStringAsFixed(2)} → ${c.referencePrice!.toStringAsFixed(2)}');
    }
    return parts.join(' · ');
  }
}
