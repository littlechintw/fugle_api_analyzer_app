import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// 一個技術指標的說明條目
class IndicatorDoc {
  final String name;
  final String fullName;
  final String purpose;
  final List<String> howToRead;
  final String formula;
  final List<String> useCases; // 適用於：當沖、短期、中長期
  const IndicatorDoc({
    required this.name,
    required this.fullName,
    required this.purpose,
    required this.howToRead,
    required this.formula,
    required this.useCases,
  });
}

class IndicatorDocs {
  static const ma = IndicatorDoc(
    name: 'MA',
    fullName: '移動平均線 Moving Average',
    purpose: '過濾雜訊、辨識中長期趨勢方向。短期均線向上穿越長期均線稱「黃金交叉」，反之為「死亡交叉」。',
    howToRead: [
      '價格站上 MA：趨勢偏多。',
      '短中長 MA 由上到下排列 (5>10>20>60)：多頭排列，趨勢強。',
      '空頭排列則相反，常為持續下跌訊號。',
    ],
    formula: 'MA_N = (P₁ + P₂ + … + P_N) / N',
    useCases: ['短期 5/10', '中期 20', '長期 60/240'],
  );

  static const bias = IndicatorDoc(
    name: 'BIAS',
    fullName: '乖離率',
    purpose: '衡量價格偏離均線的程度，過大常表示短線過熱或超賣。',
    howToRead: [
      '20MA 乖離率 > +8%：短線過熱，留意拉回。',
      '20MA 乖離率 < -8%：短線超賣，可能反彈。',
      '不同股性閾值不同，權值股建議 4%/-4%，中小型可放寬到 8%。',
    ],
    formula: 'BIAS = (收盤 − MA) / MA × 100%',
    useCases: ['短期', '當沖'],
  );

  static const rsi = IndicatorDoc(
    name: 'RSI',
    fullName: '相對強弱指標 Relative Strength Index',
    purpose: '比較近 N 期上漲與下跌力道，數值 0–100。70 以上偏熱、30 以下偏冷。',
    howToRead: [
      'RSI > 70：超買區，注意回檔風險。',
      'RSI < 30：超賣區，可能反彈。',
      'RSI 與股價形成背離 (價創高 RSI 沒創高) 是反轉警訊。',
    ],
    formula: 'RSI = 100 − 100 / (1 + 平均漲幅 / 平均跌幅)',
    useCases: ['短期', '中期'],
  );

  static const macd = IndicatorDoc(
    name: 'MACD',
    fullName: '指數平滑移動平均線',
    purpose: '判斷趨勢方向與動能。DIF 上穿 DEA 為金叉、下穿為死叉；柱狀體放大表示動能增強。',
    howToRead: [
      'DIF 在 0 軸之上：多頭格局；之下：空頭格局。',
      '柱狀體由負轉正：買進訊號；由正轉負：賣出訊號。',
      '價格創高但柱狀體未創高：動能衰竭，潛在反轉。',
    ],
    formula: 'DIF = EMA12 − EMA26；DEA = EMA(DIF, 9)；Hist = 2 × (DIF − DEA)',
    useCases: ['中期', '長期'],
  );

  static const kd = IndicatorDoc(
    name: 'KD',
    fullName: '隨機指標 Stochastic Oscillator',
    purpose: '比較收盤價在近 N 期高低區間中的相對位置，反應短線買賣壓。台股慣用 9-3-3 設定。',
    howToRead: [
      'K 線由下往上穿越 D 線且 < 30：低檔黃金交叉，買進訊號。',
      'K 線由上往下穿越 D 線且 > 70：高檔死亡交叉，賣出訊號。',
      'K、D 同時 > 80 為高檔鈍化、< 20 為低檔鈍化，趨勢可能延續。',
    ],
    formula: 'RSV = (C − Lₙ) / (Hₙ − Lₙ) × 100；K = ⅔·K₋₁ + ⅓·RSV；D = ⅔·D₋₁ + ⅓·K',
    useCases: ['當沖', '短期'],
  );

  static const bollinger = IndicatorDoc(
    name: 'Bollinger',
    fullName: '布林通道 Bollinger Bands',
    purpose: '以 N 期均線為中軸，上下 2 倍標準差形成價格通道，反映波動率變化。',
    howToRead: [
      '價格觸碰上軌：短線過熱；觸碰下軌：短線超賣。',
      '通道收斂 (寬度 < 6%)：能量蓄積，常為大行情前夜。',
      '通道擴張：趨勢加速，順勢操作。',
    ],
    formula: 'Mid = MA20；Upper = Mid + 2σ；Lower = Mid − 2σ',
    useCases: ['短期', '中期'],
  );

  static const obv = IndicatorDoc(
    name: 'OBV',
    fullName: '能量潮 On-Balance Volume',
    purpose: '把成交量乘上漲跌方向，累積觀察「資金流向」。價格與 OBV 同步創高表示資金推升有力。',
    howToRead: [
      'OBV 與股價同步創高：上漲動能健康。',
      'OBV 提前股價走弱：主力可能在出貨。',
      'OBV 提前股價走強：可能築底結束。',
    ],
    formula: 'OBV_i = OBV_{i-1} ± Volume (隨收盤漲跌符號)',
    useCases: ['中期', '長期'],
  );

  static const williams = IndicatorDoc(
    name: 'W%R',
    fullName: '威廉指標 Williams %R',
    purpose: '反映收盤價在近 N 期區間中的相對位置，與 KD 類似但更靈敏。',
    howToRead: [
      '%R > -20：超買區，回檔機率升高。',
      '%R < -80：超賣區，反彈機率升高。',
      '由極端區回頭穿越 -50 線視為趨勢轉換訊號。',
    ],
    formula: '%R = -100 × (Hₙ − C) / (Hₙ − Lₙ)',
    useCases: ['當沖', '短期'],
  );

  static const atr = IndicatorDoc(
    name: 'ATR',
    fullName: '平均真實波動範圍 Average True Range',
    purpose: '衡量價格的「日內波動幅度」，用來決定停損距離與部位大小。',
    howToRead: [
      'ATR 上升：波動加大，宜縮小部位、放大停損。',
      'ATR 下降：盤整壓縮，宜等待突破。',
      '常用 N=14；停損可設「進場價 ± 1.5~3 倍 ATR」。',
    ],
    formula: 'TR = max(H−L, |H−C₋₁|, |L−C₋₁|)；ATR = Wilder MA(TR, 14)',
    useCases: ['當沖', '短期', '部位管理'],
  );
}

void showIndicatorInfo(BuildContext context, IndicatorDoc doc) {
  showDialog(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: AppTheme.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    doc.name,
                    style: const TextStyle(
                      color: AppTheme.accent,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      doc.fullName,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _section('用途'),
              Text(doc.purpose, style: _body),
              const SizedBox(height: 12),
              _section('判讀'),
              ...doc.howToRead.map((s) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text('• $s', style: _body),
                  )),
              const SizedBox(height: 12),
              _section('公式'),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.bgSurface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Text(
                  doc.formula,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontFamily: 'monospace',
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _section('適用情境'),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final c in doc.useCases)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        c,
                        style: const TextStyle(
                          color: AppTheme.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('關閉'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _section(String title) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 11,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

const _body = TextStyle(
  color: AppTheme.textPrimary,
  fontSize: 13,
  height: 1.55,
);
