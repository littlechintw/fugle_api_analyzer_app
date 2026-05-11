import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../indicators/analysis.dart';

/// 技術面綜合評分卡 — 把現有 7 個指標投票加總顯示。
/// 注意：這是「指標訊號彙整」不是「未來漲跌機率」。
class SignalCard extends StatelessWidget {
  final SignalReport report;
  const SignalCard({super.key, required this.report});

  Color _color() => switch (report.bias) {
        SignalBias.strongBull => AppTheme.bullish,
        SignalBias.bull => AppTheme.bullish,
        SignalBias.neutral => AppTheme.neutral,
        SignalBias.bear => AppTheme.bearish,
        SignalBias.strongBear => AppTheme.bearish,
      };

  String _emoji() => switch (report.bias) {
        SignalBias.strongBull => '🔥',
        SignalBias.bull => '📈',
        SignalBias.neutral => '⚖️',
        SignalBias.bear => '📉',
        SignalBias.strongBear => '❄️',
      };

  @override
  Widget build(BuildContext context) {
    if (report.totalVotes == 0) {
      return const SizedBox.shrink();
    }
    final c = _color();
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
              const Icon(Icons.insights,
                  size: 16, color: AppTheme.accent),
              const SizedBox(width: 6),
              const Text(
                '技術面綜合評分',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _showExplanation(context),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.help_outline,
                      size: 16, color: AppTheme.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(_emoji(), style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    report.bias.label,
                    style: TextStyle(
                      color: c,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '訊號同向度 ${report.agreementPct.toStringAsFixed(0)}%  '
                    '· 總分 ${report.totalScore >= 0 ? '+' : ''}${report.totalScore}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _miniStat('多', report.bullishCount, AppTheme.bullish),
                  _miniStat('空', report.bearishCount, AppTheme.bearish),
                  _miniStat('中', report.neutralCount, AppTheme.neutral),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 投票進度條
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 6,
              child: Row(
                children: [
                  Expanded(
                    flex: report.bullishCount + 1,
                    child: Container(color: AppTheme.bullish),
                  ),
                  Expanded(
                    flex: report.neutralCount + 1,
                    child: Container(color: AppTheme.neutral),
                  ),
                  Expanded(
                    flex: report.bearishCount + 1,
                    child: Container(color: AppTheme.bearish),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 逐項票數
          ...report.votes.map((v) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: v.score > 0
                            ? AppTheme.bullish.withValues(alpha: 0.18)
                            : v.score < 0
                                ? AppTheme.bearish.withValues(alpha: 0.18)
                                : AppTheme.bgSurface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        v.score > 0
                            ? '多'
                            : (v.score < 0 ? '空' : '中'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: v.score > 0
                              ? AppTheme.bullish
                              : v.score < 0
                                  ? AppTheme.bearish
                                  : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 48,
                      child: Text(
                        v.name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        v.detail,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _miniStat(String l, int v, Color c) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 10)),
            const SizedBox(width: 4),
            Text(v.toString(),
                style: TextStyle(
                    color: c,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      );

  void _showExplanation(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppTheme.borderColor),
        ),
        child: const Padding(
          padding: EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '什麼是「綜合評分」？',
                  style: TextStyle(
                    color: AppTheme.accent,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  '此評分將 7 項技術指標（MA、RSI、MACD、KD、BIAS、W%R、量能）的當前狀態各自評為 +1 (偏多) / -1 (偏空) / 0 (中性)，加總後得出「多頭/空頭/中性」傾向，並顯示「訊號同向度」表示有多少比例的指標朝同方向。',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  '⚠️ 重要說明',
                  style: TextStyle(
                    color: AppTheme.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '這個分數是「技術指標訊號的彙整」，不是「未來漲跌的機率預測」。\n\n'
                  '即使顯示「強力偏多」也不保證一定上漲；同向度越高表示「目前各指標訊號一致性高」，仍可能因消息面、籌碼面而失效。\n\n'
                  '建議搭配基本面、籌碼面、消息面與停損規則使用，不要單獨作為交易依據。',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
