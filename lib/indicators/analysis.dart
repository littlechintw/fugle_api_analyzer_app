import 'dart:math' as math;

import '../data/models/candle.dart';
import 'indicators.dart';

/// 波動度分析結果
class VolatilityReport {
  final double atr;             // 14日 ATR
  final double atrPctOfClose;   // ATR / 收盤價，相對日波幅
  final double atrHistMean;     // 過去 60 日 ATR 平均
  final double historicalVolAnnual; // 歷史年化波動率（標準差）
  final double bandwidthPct;    // 布林通道寬度（百分比）
  final double expectedLow;     // 預期波動下緣 = 收盤 - 2*ATR
  final double expectedHigh;    // 預期波動上緣 = 收盤 + 2*ATR
  final VolatilityLevel level;
  const VolatilityReport({
    required this.atr,
    required this.atrPctOfClose,
    required this.atrHistMean,
    required this.historicalVolAnnual,
    required this.bandwidthPct,
    required this.expectedLow,
    required this.expectedHigh,
    required this.level,
  });

  bool get aboveAverage => atr > atrHistMean * 1.2;
  bool get belowAverage => atr < atrHistMean * 0.8;
}

enum VolatilityLevel { low, normal, high, extreme }

extension VolatilityLevelLabel on VolatilityLevel {
  String get label => switch (this) {
        VolatilityLevel.low => '低波動',
        VolatilityLevel.normal => '正常',
        VolatilityLevel.high => '高波動',
        VolatilityLevel.extreme => '劇烈',
      };
  String get advice => switch (this) {
        VolatilityLevel.low => '盤整壓縮中，等待突破方向。建議降低部位或耐心觀望。',
        VolatilityLevel.normal => '波動度位於常態區間，依趨勢策略操作即可。',
        VolatilityLevel.high =>
          '波動加大，停損距離宜放寬到 2×ATR 以上；當沖留意假突破。',
        VolatilityLevel.extreme =>
          '極端波動，多為消息面或恐慌盤。建議縮小部位、避免重壓。',
      };
}

class VolatilityAnalyser {
  static VolatilityReport analyse(List<Candle> candles) {
    if (candles.length < 30) {
      return const VolatilityReport(
        atr: 0,
        atrPctOfClose: 0,
        atrHistMean: 0,
        historicalVolAnnual: 0,
        bandwidthPct: 0,
        expectedLow: 0,
        expectedHigh: 0,
        level: VolatilityLevel.normal,
      );
    }
    final last = candles.length - 1;
    final close = candles[last].close;
    final atrSeries = Indicators.atr(candles);
    final atr = atrSeries[last].isNaN ? 0.0 : atrSeries[last];

    // 歷史 ATR 平均
    final atrClean = atrSeries.where((v) => !v.isNaN).toList();
    final histMean = atrClean.isEmpty
        ? 0.0
        : atrClean.reduce((a, b) => a + b) / atrClean.length;

    // 年化波動率：日 log return 標準差 * sqrt(252)
    final returns = <double>[];
    for (var i = 1; i < candles.length; i++) {
      if (candles[i - 1].close <= 0) continue;
      returns.add(math.log(candles[i].close / candles[i - 1].close));
    }
    final mean = returns.isEmpty
        ? 0
        : returns.reduce((a, b) => a + b) / returns.length;
    var variance = 0.0;
    for (final r in returns) {
      variance += (r - mean) * (r - mean);
    }
    variance = returns.length < 2 ? 0 : variance / (returns.length - 1);
    final dailySd = math.sqrt(variance);
    final annualVol = dailySd * math.sqrt(252);

    // 布林寬度
    final boll = Indicators.bollinger(candles);
    final bw = (boll.upper[last].isNaN ||
            boll.lower[last].isNaN ||
            boll.middle[last].isNaN ||
            boll.middle[last] == 0)
        ? 0.0
        : (boll.upper[last] - boll.lower[last]) / boll.middle[last] * 100;

    // 等級
    VolatilityLevel level;
    final ratio = histMean == 0 ? 1.0 : atr / histMean;
    if (ratio < 0.7) {
      level = VolatilityLevel.low;
    } else if (ratio < 1.3) {
      level = VolatilityLevel.normal;
    } else if (ratio < 1.8) {
      level = VolatilityLevel.high;
    } else {
      level = VolatilityLevel.extreme;
    }

    return VolatilityReport(
      atr: atr,
      atrPctOfClose: close == 0 ? 0 : atr / close * 100,
      atrHistMean: histMean,
      historicalVolAnnual: annualVol * 100,
      bandwidthPct: bw,
      expectedLow: close - 2 * atr,
      expectedHigh: close + 2 * atr,
      level: level,
    );
  }
}

// ============== 技術面綜合評分 ==============

/// 單一指標的投票
class IndicatorVote {
  final String name;
  final int score; // +1 = 多 / -1 = 空 / 0 = 中性
  final String detail;
  const IndicatorVote({
    required this.name,
    required this.score,
    required this.detail,
  });
}

class SignalReport {
  final int bullishCount;
  final int bearishCount;
  final int neutralCount;
  final int totalScore;      // 加總 (-N..+N)
  final List<IndicatorVote> votes;
  final SignalBias bias;
  final double agreementPct; // 同方向比例 (0..100)
  const SignalReport({
    required this.bullishCount,
    required this.bearishCount,
    required this.neutralCount,
    required this.totalScore,
    required this.votes,
    required this.bias,
    required this.agreementPct,
  });

  int get totalVotes => bullishCount + bearishCount + neutralCount;
}

enum SignalBias { strongBull, bull, neutral, bear, strongBear }

extension SignalBiasLabel on SignalBias {
  String get label => switch (this) {
        SignalBias.strongBull => '強力偏多',
        SignalBias.bull => '偏多',
        SignalBias.neutral => '中性',
        SignalBias.bear => '偏空',
        SignalBias.strongBear => '強力偏空',
      };
}

class SignalAnalyser {
  static SignalReport analyse(List<Candle> candles) {
    final votes = <IndicatorVote>[];
    if (candles.length < 60) {
      return SignalReport(
        bullishCount: 0,
        bearishCount: 0,
        neutralCount: 0,
        totalScore: 0,
        votes: votes,
        bias: SignalBias.neutral,
        agreementPct: 0,
      );
    }
    final last = candles.length - 1;
    final close = candles[last].close;

    // 1. MA 多空頭排列
    final ma5 = Indicators.sma(candles, 5)[last];
    final ma10 = Indicators.sma(candles, 10)[last];
    final ma20 = Indicators.sma(candles, 20)[last];
    final ma60 = Indicators.sma(candles, 60)[last];
    if ([ma5, ma10, ma20, ma60].every((v) => !v.isNaN)) {
      if (ma5 > ma10 && ma10 > ma20 && ma20 > ma60) {
        votes.add(const IndicatorVote(
            name: 'MA', score: 1, detail: '5/10/20/60 多頭排列'));
      } else if (ma5 < ma10 && ma10 < ma20 && ma20 < ma60) {
        votes.add(const IndicatorVote(
            name: 'MA', score: -1, detail: '5/10/20/60 空頭排列'));
      } else if (close > ma20) {
        votes.add(const IndicatorVote(
            name: 'MA', score: 1, detail: '股價站上 20MA'));
      } else if (close < ma20) {
        votes.add(const IndicatorVote(
            name: 'MA', score: -1, detail: '股價跌破 20MA'));
      } else {
        votes.add(const IndicatorVote(
            name: 'MA', score: 0, detail: '均線糾結'));
      }
    }

    // 2. RSI
    final rsi = Indicators.rsi(candles)[last];
    if (!rsi.isNaN) {
      if (rsi > 50 && rsi < 70) {
        votes.add(IndicatorVote(
            name: 'RSI', score: 1, detail: 'RSI=${rsi.toStringAsFixed(1)} 強勢區'));
      } else if (rsi < 50 && rsi > 30) {
        votes.add(IndicatorVote(
            name: 'RSI', score: -1, detail: 'RSI=${rsi.toStringAsFixed(1)} 弱勢區'));
      } else if (rsi >= 70) {
        votes.add(IndicatorVote(
            name: 'RSI', score: 0, detail: 'RSI=${rsi.toStringAsFixed(1)} 超買警示'));
      } else if (rsi <= 30) {
        votes.add(IndicatorVote(
            name: 'RSI', score: 0, detail: 'RSI=${rsi.toStringAsFixed(1)} 超賣可反彈'));
      }
    }

    // 3. MACD
    final macd = Indicators.macd(candles);
    if (!macd.dif[last].isNaN && !macd.dea[last].isNaN) {
      if (macd.dif[last] > macd.dea[last] && macd.dif[last] > 0) {
        votes.add(const IndicatorVote(
            name: 'MACD', score: 1, detail: 'DIF > DEA 且 > 0 軸'));
      } else if (macd.dif[last] < macd.dea[last] && macd.dif[last] < 0) {
        votes.add(const IndicatorVote(
            name: 'MACD', score: -1, detail: 'DIF < DEA 且 < 0 軸'));
      } else {
        votes.add(const IndicatorVote(
            name: 'MACD', score: 0, detail: '訊號交織不明'));
      }
    }

    // 4. KD
    final kd = Indicators.kd(candles);
    if (!kd.k[last].isNaN && !kd.d[last].isNaN) {
      final k = kd.k[last], d = kd.d[last];
      if (k > d && k < 80) {
        votes.add(IndicatorVote(
            name: 'KD',
            score: 1,
            detail: 'K=${k.toStringAsFixed(1)} > D=${d.toStringAsFixed(1)}'));
      } else if (k < d && k > 20) {
        votes.add(IndicatorVote(
            name: 'KD',
            score: -1,
            detail: 'K=${k.toStringAsFixed(1)} < D=${d.toStringAsFixed(1)}'));
      } else {
        votes.add(IndicatorVote(
            name: 'KD',
            score: 0,
            detail: '位於高低檔極端區，待轉折'));
      }
    }

    // 5. BIAS(20)
    final bias = Indicators.bias(candles, 20)[last];
    if (!bias.isNaN) {
      if (bias > 8) {
        votes.add(IndicatorVote(
            name: 'BIAS',
            score: -1,
            detail: '20日乖離 ${bias.toStringAsFixed(2)}% 過熱'));
      } else if (bias < -8) {
        votes.add(IndicatorVote(
            name: 'BIAS',
            score: 1,
            detail: '20日乖離 ${bias.toStringAsFixed(2)}% 超賣可彈'));
      } else if (bias > 0) {
        votes.add(IndicatorVote(
            name: 'BIAS',
            score: 1,
            detail: '正乖離 ${bias.toStringAsFixed(2)}%'));
      } else {
        votes.add(IndicatorVote(
            name: 'BIAS',
            score: -1,
            detail: '負乖離 ${bias.toStringAsFixed(2)}%'));
      }
    }

    // 6. Williams %R
    final wr = Indicators.williamsR(candles)[last];
    if (!wr.isNaN) {
      if (wr > -50 && wr < -20) {
        votes.add(IndicatorVote(
            name: 'W%R',
            score: 1,
            detail: '%R=${wr.toStringAsFixed(1)} 偏強區'));
      } else if (wr < -50 && wr > -80) {
        votes.add(IndicatorVote(
            name: 'W%R',
            score: -1,
            detail: '%R=${wr.toStringAsFixed(1)} 偏弱區'));
      } else if (wr > -20) {
        votes.add(IndicatorVote(
            name: 'W%R',
            score: 0,
            detail: '%R=${wr.toStringAsFixed(1)} 超買'));
      } else {
        votes.add(IndicatorVote(
            name: 'W%R',
            score: 0,
            detail: '%R=${wr.toStringAsFixed(1)} 超賣'));
      }
    }

    // 7. 量能 (20 日均量)
    if (candles.length >= 21) {
      final recent = candles
              .sublist(candles.length - 21, candles.length - 1)
              .map((c) => c.volume)
              .reduce((a, b) => a + b) /
          20;
      final curVol = candles[last].volume;
      if (recent > 0) {
        if (curVol > recent * 1.5 && candles[last].isBullish) {
          votes.add(const IndicatorVote(
              name: '量能', score: 1, detail: '放量上漲，買盤積極'));
        } else if (curVol > recent * 1.5 && !candles[last].isBullish) {
          votes.add(const IndicatorVote(
              name: '量能', score: -1, detail: '放量下跌，賣壓沉重'));
        } else if (curVol < recent * 0.6) {
          votes.add(const IndicatorVote(
              name: '量能', score: 0, detail: '量縮觀望'));
        } else {
          votes.add(const IndicatorVote(
              name: '量能', score: 0, detail: '量能正常'));
        }
      }
    }

    final bull = votes.where((v) => v.score > 0).length;
    final bear = votes.where((v) => v.score < 0).length;
    final neu = votes.where((v) => v.score == 0).length;
    final total = votes.fold<int>(0, (a, v) => a + v.score);
    final majority = math.max(bull, bear);
    final agree = votes.isEmpty ? 0.0 : majority / votes.length * 100;

    SignalBias biasLevel;
    if (total >= 4) {
      biasLevel = SignalBias.strongBull;
    } else if (total >= 2) {
      biasLevel = SignalBias.bull;
    } else if (total <= -4) {
      biasLevel = SignalBias.strongBear;
    } else if (total <= -2) {
      biasLevel = SignalBias.bear;
    } else {
      biasLevel = SignalBias.neutral;
    }

    return SignalReport(
      bullishCount: bull,
      bearishCount: bear,
      neutralCount: neu,
      totalScore: total,
      votes: votes,
      bias: biasLevel,
      agreementPct: agree,
    );
  }
}
