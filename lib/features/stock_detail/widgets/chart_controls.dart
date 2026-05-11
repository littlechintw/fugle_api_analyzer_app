import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/providers/providers.dart';

/// K 線週期 + 區間控制列
class ChartControls extends ConsumerWidget {
  const ChartControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opts = ref.watch(chartOptionsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 週期：日 / 週 / 月
        SizedBox(
          height: 30,
          child: Row(
            children: [
              for (final tf in ChartTimeframe.values)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(tf.label,
                        style: const TextStyle(fontSize: 11)),
                    selected: opts.timeframe == tf,
                    onSelected: (_) => ref
                        .read(chartOptionsProvider.notifier)
                        .setTimeframe(tf),
                    backgroundColor: AppTheme.bgSurface,
                    selectedColor:
                        AppTheme.accent.withValues(alpha: 0.20),
                    labelStyle: TextStyle(
                      color: opts.timeframe == tf
                          ? AppTheme.accent
                          : AppTheme.textSecondary,
                    ),
                    side: BorderSide(
                      color: opts.timeframe == tf
                          ? AppTheme.accent
                          : AppTheme.borderColor,
                    ),
                    materialTapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        // 區間 + 大盤對比 toggle
        SizedBox(
          height: 30,
          child: Row(
            children: [
              Expanded(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final r in ChartRange.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(r.label,
                              style: const TextStyle(fontSize: 11)),
                          selected: opts.range == r,
                          onSelected: (_) => ref
                              .read(chartOptionsProvider.notifier)
                              .setRange(r),
                          backgroundColor: AppTheme.bgSurface,
                          selectedColor:
                              AppTheme.accent.withValues(alpha: 0.20),
                          labelStyle: TextStyle(
                            color: opts.range == r
                                ? AppTheme.accent
                                : AppTheme.textSecondary,
                          ),
                          side: BorderSide(
                            color: opts.range == r
                                ? AppTheme.accent
                                : AppTheme.borderColor,
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _CompareIndexToggle(),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompareIndexToggle extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(compareIndexProvider);
    return InkWell(
      onTap: () => ref.read(compareIndexProvider.notifier).toggle(),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: on
              ? const Color(0xFF8E9DFF).withValues(alpha: 0.20)
              : AppTheme.bgSurface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: on
                ? const Color(0xFF8E9DFF)
                : AppTheme.borderColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              on ? Icons.check_box : Icons.check_box_outline_blank,
              size: 14,
              color: on
                  ? const Color(0xFF8E9DFF)
                  : AppTheme.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              '對比加權',
              style: TextStyle(
                color: on
                    ? const Color(0xFF8E9DFF)
                    : AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
