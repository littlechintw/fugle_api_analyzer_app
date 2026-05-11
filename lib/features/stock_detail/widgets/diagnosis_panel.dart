import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../indicators/indicators.dart';

class DiagnosisPanel extends StatelessWidget {
  final List<DiagnosisTag> tags;
  const DiagnosisPanel({super.key, required this.tags});

  Color _bg(DiagnosisSentiment s) => switch (s) {
        DiagnosisSentiment.bullish => AppTheme.bullish.withValues(alpha: 0.14),
        DiagnosisSentiment.bearish => AppTheme.bearish.withValues(alpha: 0.14),
        DiagnosisSentiment.warning => AppTheme.accent.withValues(alpha: 0.16),
        DiagnosisSentiment.neutral => AppTheme.bgSurface,
      };
  Color _fg(DiagnosisSentiment s) => switch (s) {
        DiagnosisSentiment.bullish => AppTheme.bullish,
        DiagnosisSentiment.bearish => AppTheme.bearish,
        DiagnosisSentiment.warning => AppTheme.accent,
        DiagnosisSentiment.neutral => AppTheme.textPrimary,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
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
              Icon(Icons.insights, size: 16, color: AppTheme.accent),
              SizedBox(width: 6),
              Text(
                '技術診斷',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in tags)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _bg(t.sentiment),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _fg(t.sentiment).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(t.emoji,
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        t.label,
                        style: TextStyle(
                          color: _fg(t.sentiment),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ...tags.map(
            (t) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                '• ${t.label}：${t.detail}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
