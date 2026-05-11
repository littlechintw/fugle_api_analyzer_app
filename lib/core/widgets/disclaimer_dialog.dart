import 'package:flutter/material.dart';

import '../../data/services/hive_service.dart';
import '../theme/app_theme.dart';

const _ackKey = 'disclaimer_ack_v1';

/// 第一次開啟時呼叫；已同意過就不再顯示
Future<void> ensureDisclaimerShown(BuildContext context) async {
  final box = HiveService.instance.settings;
  final acked = box.get(_ackKey) as bool? ?? false;
  if (acked) return;

  if (!context.mounted) return;
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Dialog(
      backgroundColor: AppTheme.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: AppTheme.accent, size: 22),
                  SizedBox(width: 8),
                  Text(
                    '使用前請閱讀',
                    style: TextStyle(
                      color: AppTheme.accent,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                '本 App 提供的所有資訊（包含股價、K 線、技術指標、診斷標籤、'
                '綜合評分、波動度分析、三大法人買賣超等），皆為 **技術面參考資料**，'
                '不構成任何投資建議或買賣依據。',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '請特別留意：',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '• 「強力偏多」「過熱」「金叉」等診斷標籤僅根據歷史價格演算得出，不保證未來走勢\n'
                '• 「綜合評分」是技術指標投票結果，不是漲跌機率預測\n'
                '• 三大法人買賣超為交易所公開資料，僅反映過去動向\n'
                '• 任何交易損失需自行負責\n'
                '• 資料可能有延遲或誤差，重要決策請以官方來源為準',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('我了解，繼續使用'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  if (ok == true) {
    await box.put(_ackKey, true);
  }
}
