import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class DataSourcesFooter extends StatelessWidget {
  const DataSourcesFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline,
                  size: 11, color: AppTheme.textSecondary),
              SizedBox(width: 4),
              Text(
                '資料來源',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            '• 報價、K 線、五檔、52 週統計：Fugle Market Data API\n'
            '• 三大法人買賣超：臺灣證券交易所公開資料 (T86)\n'
            '• 所有指標於本地計算，不會傳送個股資訊到第三方伺服器',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 10,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppTheme.accent.withValues(alpha: 0.25),
              ),
            ),
            child: const Text(
              '⚠ 本頁所有分析、指標、診斷標籤、綜合評分皆為技術面參考，'
              '不構成任何投資建議。實際投資請自行評估風險。',
              style: TextStyle(
                color: AppTheme.accent,
                fontSize: 10,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
