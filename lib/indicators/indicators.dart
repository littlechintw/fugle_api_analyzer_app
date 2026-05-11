import 'dart:math' as math;

import '../data/models/candle.dart';

/// 技術指標純函式集合。
///
/// 輸入永遠是時間排序 (舊→新) 的 List<Candle>。
/// 所有輸出 List 長度與輸入相同；無法計算的點以 `double.nan` 表示。
class Indicators {
  /// 簡單移動平均 (SMA)
  static List<double> sma(List<Candle> candles, int period) {
    final out = List<double>.filled(candles.length, double.nan);
    if (period <= 0 || candles.length < period) return out;
    double sum = 0;
    for (var i = 0; i < candles.length; i++) {
      sum += candles[i].close;
      if (i >= period) sum -= candles[i - period].close;
      if (i >= period - 1) out[i] = sum / period;
    }
    return out;
  }

  /// 乖離率 BIAS = (Close - MA) / MA * 100
  static List<double> bias(List<Candle> candles, int period) {
    final ma = sma(candles, period);
    final out = List<double>.filled(candles.length, double.nan);
    for (var i = 0; i < candles.length; i++) {
      if (ma[i].isNaN || ma[i] == 0) continue;
      out[i] = (candles[i].close - ma[i]) / ma[i] * 100;
    }
    return out;
  }

  /// 相對強弱指標 RSI (Wilder 平滑)
  static List<double> rsi(List<Candle> candles, {int period = 14}) {
    final out = List<double>.filled(candles.length, double.nan);
    if (candles.length <= period) return out;
    double avgGain = 0;
    double avgLoss = 0;
    for (var i = 1; i <= period; i++) {
      final change = candles[i].close - candles[i - 1].close;
      if (change >= 0) {
        avgGain += change;
      } else {
        avgLoss += -change;
      }
    }
    avgGain /= period;
    avgLoss /= period;
    out[period] = avgLoss == 0 ? 100 : 100 - 100 / (1 + avgGain / avgLoss);
    for (var i = period + 1; i < candles.length; i++) {
      final change = candles[i].close - candles[i - 1].close;
      final gain = change > 0 ? change : 0;
      final loss = change < 0 ? -change : 0;
      avgGain = (avgGain * (period - 1) + gain) / period;
      avgLoss = (avgLoss * (period - 1) + loss) / period;
      out[i] = avgLoss == 0 ? 100 : 100 - 100 / (1 + avgGain / avgLoss);
    }
    return out;
  }

  /// MACD: 回傳 (dif, dea, hist)
  static MacdResult macd(
    List<Candle> candles, {
    int fast = 12,
    int slow = 26,
    int signal = 9,
  }) {
    final emaFast = _ema(candles.map((c) => c.close).toList(), fast);
    final emaSlow = _ema(candles.map((c) => c.close).toList(), slow);
    final dif = List<double>.generate(candles.length, (i) {
      if (emaFast[i].isNaN || emaSlow[i].isNaN) return double.nan;
      return emaFast[i] - emaSlow[i];
    });
    final dea = _ema(dif, signal);
    final hist = List<double>.generate(candles.length, (i) {
      if (dif[i].isNaN || dea[i].isNaN) return double.nan;
      return (dif[i] - dea[i]) * 2;
    });
    return MacdResult(dif: dif, dea: dea, histogram: hist);
  }

  /// KD (Stochastic Oscillator) — 台股慣用 9-3-3
  /// 回傳 (K, D)。RSV = (Close - Lowest_N) / (Highest_N - Lowest_N) * 100
  /// K = 2/3 * 前 K + 1/3 * RSV ；D = 2/3 * 前 D + 1/3 * K
  static KdResult kd(List<Candle> candles, {int period = 9}) {
    final n = candles.length;
    final k = List<double>.filled(n, double.nan);
    final d = List<double>.filled(n, double.nan);
    if (n < period) return KdResult(k: k, d: d);
    double prevK = 50;
    double prevD = 50;
    for (var i = period - 1; i < n; i++) {
      final window = candles.sublist(i - period + 1, i + 1);
      final hi = window.map((c) => c.high).reduce((a, b) => a > b ? a : b);
      final lo = window.map((c) => c.low).reduce((a, b) => a < b ? a : b);
      final rsv =
          (hi - lo).abs() < 1e-9 ? 50.0 : (candles[i].close - lo) / (hi - lo) * 100;
      final curK = prevK * 2 / 3 + rsv / 3;
      final curD = prevD * 2 / 3 + curK / 3;
      k[i] = curK;
      d[i] = curD;
      prevK = curK;
      prevD = curD;
    }
    return KdResult(k: k, d: d);
  }

  /// 布林通道 Bollinger Bands — 中軌 SMA20，上下軌 ±2σ
  static BollingerResult bollinger(
    List<Candle> candles, {
    int period = 20,
    double k = 2,
  }) {
    final n = candles.length;
    final mid = sma(candles, period);
    final up = List<double>.filled(n, double.nan);
    final lo = List<double>.filled(n, double.nan);
    for (var i = period - 1; i < n; i++) {
      double s = 0;
      for (var j = i - period + 1; j <= i; j++) {
        final dx = candles[j].close - mid[i];
        s += dx * dx;
      }
      final sd = (s / period).abs() < 1e-12 ? 0.0 : (s / period).abs();
      final std = _safeSqrt(sd);
      up[i] = mid[i] + k * std;
      lo[i] = mid[i] - k * std;
    }
    return BollingerResult(middle: mid, upper: up, lower: lo);
  }

  static double _safeSqrt(double v) => v <= 0 ? 0 : math.sqrt(v);

  /// OBV (On-Balance Volume) — 累積方向化成交量
  static List<double> obv(List<Candle> candles) {
    final out = List<double>.filled(candles.length, 0);
    for (var i = 1; i < candles.length; i++) {
      final diff = candles[i].close - candles[i - 1].close;
      if (diff > 0) {
        out[i] = out[i - 1] + candles[i].volume;
      } else if (diff < 0) {
        out[i] = out[i - 1] - candles[i].volume;
      } else {
        out[i] = out[i - 1];
      }
    }
    return out;
  }

  /// Williams %R — N 期內最高最低相對位置
  /// = -100 * (Hn - C) / (Hn - Ln)，介於 -100..0；< -80 超賣、> -20 超買
  static List<double> williamsR(List<Candle> candles, {int period = 14}) {
    final n = candles.length;
    final out = List<double>.filled(n, double.nan);
    if (n < period) return out;
    for (var i = period - 1; i < n; i++) {
      final window = candles.sublist(i - period + 1, i + 1);
      final hi = window.map((c) => c.high).reduce((a, b) => a > b ? a : b);
      final lo = window.map((c) => c.low).reduce((a, b) => a < b ? a : b);
      if ((hi - lo).abs() < 1e-9) {
        out[i] = -50;
      } else {
        out[i] = -100 * (hi - candles[i].close) / (hi - lo);
      }
    }
    return out;
  }

  /// ATR (Average True Range) — 平均真實波動範圍 (Wilder 平滑)
  static List<double> atr(List<Candle> candles, {int period = 14}) {
    final n = candles.length;
    final out = List<double>.filled(n, double.nan);
    if (n <= period) return out;
    final tr = List<double>.filled(n, 0);
    for (var i = 1; i < n; i++) {
      final hl = candles[i].high - candles[i].low;
      final hc = (candles[i].high - candles[i - 1].close).abs();
      final lc = (candles[i].low - candles[i - 1].close).abs();
      tr[i] = [hl, hc, lc].reduce((a, b) => a > b ? a : b);
    }
    double acc = 0;
    for (var i = 1; i <= period; i++) {
      acc += tr[i];
    }
    out[period] = acc / period;
    for (var i = period + 1; i < n; i++) {
      out[i] = (out[i - 1] * (period - 1) + tr[i]) / period;
    }
    return out;
  }

  static List<double> _ema(List<double> values, int period) {
    final out = List<double>.filled(values.length, double.nan);
    if (values.length < period || period <= 0) return out;
    final k = 2 / (period + 1);
    double sum = 0;
    for (var i = 0; i < period; i++) {
      if (values[i].isNaN) return out;
      sum += values[i];
    }
    out[period - 1] = sum / period;
    for (var i = period; i < values.length; i++) {
      if (values[i].isNaN) {
        out[i] = out[i - 1];
        continue;
      }
      out[i] = values[i] * k + out[i - 1] * (1 - k);
    }
    return out;
  }
}

class MacdResult {
  final List<double> dif;
  final List<double> dea;
  final List<double> histogram;
  const MacdResult({
    required this.dif,
    required this.dea,
    required this.histogram,
  });
}

class KdResult {
  final List<double> k;
  final List<double> d;
  const KdResult({required this.k, required this.d});
}

class BollingerResult {
  final List<double> middle;
  final List<double> upper;
  final List<double> lower;
  const BollingerResult({
    required this.middle,
    required this.upper,
    required this.lower,
  });
}

/// 診斷標籤 (給診斷面板使用)
class DiagnosisTag {
  final String emoji;
  final String label;
  final String detail;
  final DiagnosisSentiment sentiment;
  const DiagnosisTag({
    required this.emoji,
    required this.label,
    required this.detail,
    required this.sentiment,
  });
}

enum DiagnosisSentiment { bullish, bearish, warning, neutral }

class Diagnoser {
  /// 對最新 K 線產生診斷標籤
  static List<DiagnosisTag> diagnose(List<Candle> candles) {
    final tags = <DiagnosisTag>[];
    if (candles.length < 60) return tags;
    final last = candles.length - 1;

    final ma5 = Indicators.sma(candles, 5)[last];
    final ma10 = Indicators.sma(candles, 10)[last];
    final ma20 = Indicators.sma(candles, 20)[last];
    final ma60 = Indicators.sma(candles, 60)[last];
    final close = candles[last].close;

    // 均線多頭排列
    if (!_anyNaN([ma5, ma10, ma20, ma60]) &&
        ma5 > ma10 && ma10 > ma20 && ma20 > ma60) {
      tags.add(const DiagnosisTag(
        emoji: '🔥',
        label: '強勢多頭',
        detail: '5/10/20/60 MA 多頭排列',
        sentiment: DiagnosisSentiment.bullish,
      ));
    }
    // 均線空頭排列
    if (!_anyNaN([ma5, ma10, ma20, ma60]) &&
        ma5 < ma10 && ma10 < ma20 && ma20 < ma60) {
      tags.add(const DiagnosisTag(
        emoji: '❄️',
        label: '弱勢空頭',
        detail: '5/10/20/60 MA 空頭排列',
        sentiment: DiagnosisSentiment.bearish,
      ));
    }

    // 乖離率
    final bias20 = Indicators.bias(candles, 20)[last];
    if (!bias20.isNaN) {
      if (bias20 > 8) {
        tags.add(DiagnosisTag(
          emoji: '⚠️',
          label: '過熱',
          detail: '20MA 乖離率 ${bias20.toStringAsFixed(2)}% (>8%)',
          sentiment: DiagnosisSentiment.warning,
        ));
      } else if (bias20 < -8) {
        tags.add(DiagnosisTag(
          emoji: '🧊',
          label: '超跌',
          detail: '20MA 乖離率 ${bias20.toStringAsFixed(2)}% (<-8%)',
          sentiment: DiagnosisSentiment.warning,
        ));
      }
    }

    // RSI
    final rsi14 = Indicators.rsi(candles)[last];
    if (!rsi14.isNaN) {
      if (rsi14 > 70) {
        tags.add(DiagnosisTag(
          emoji: '🚨',
          label: 'RSI 超買',
          detail: 'RSI(14) = ${rsi14.toStringAsFixed(1)}',
          sentiment: DiagnosisSentiment.warning,
        ));
      } else if (rsi14 < 30) {
        tags.add(DiagnosisTag(
          emoji: '🟢',
          label: 'RSI 超賣',
          detail: 'RSI(14) = ${rsi14.toStringAsFixed(1)}',
          sentiment: DiagnosisSentiment.bullish,
        ));
      }
    }

    // MACD 金叉/死叉
    final macd = Indicators.macd(candles);
    if (candles.length >= 2) {
      final difNow = macd.dif[last];
      final deaNow = macd.dea[last];
      final difPrev = macd.dif[last - 1];
      final deaPrev = macd.dea[last - 1];
      if (!_anyNaN([difNow, deaNow, difPrev, deaPrev])) {
        if (difPrev < deaPrev && difNow > deaNow) {
          tags.add(const DiagnosisTag(
            emoji: '✨',
            label: 'MACD 金叉',
            detail: 'DIF 向上突破 DEA',
            sentiment: DiagnosisSentiment.bullish,
          ));
        } else if (difPrev > deaPrev && difNow < deaNow) {
          tags.add(const DiagnosisTag(
            emoji: '⚠️',
            label: 'MACD 死叉',
            detail: 'DIF 向下跌破 DEA',
            sentiment: DiagnosisSentiment.bearish,
          ));
        }
      }
    }

    // 量能
    if (candles.length >= 20) {
      final avgVol = candles
              .sublist(candles.length - 21, candles.length - 1)
              .map((c) => c.volume)
              .reduce((a, b) => a + b) /
          20;
      final curVol = candles[last].volume;
      if (avgVol > 0 && curVol > avgVol * 2 && candles[last].isBullish) {
        tags.add(const DiagnosisTag(
          emoji: '📈',
          label: '爆量上攻',
          detail: '成交量 >2x 20 日均量且收紅',
          sentiment: DiagnosisSentiment.bullish,
        ));
      }
    }

    // KD
    final kd = Indicators.kd(candles);
    if (candles.length >= 2) {
      final kNow = kd.k[last];
      final dNow = kd.d[last];
      final kPrev = kd.k[last - 1];
      final dPrev = kd.d[last - 1];
      if (!_anyNaN([kNow, dNow, kPrev, dPrev])) {
        if (kPrev < dPrev && kNow > dNow && kNow < 30) {
          tags.add(const DiagnosisTag(
            emoji: '⚡',
            label: 'KD 低檔金叉',
            detail: 'K 向上突破 D 且位於 30 以下 (買進訊號)',
            sentiment: DiagnosisSentiment.bullish,
          ));
        } else if (kPrev > dPrev && kNow < dNow && kNow > 70) {
          tags.add(const DiagnosisTag(
            emoji: '⚠️',
            label: 'KD 高檔死叉',
            detail: 'K 向下跌破 D 且位於 70 以上 (賣出訊號)',
            sentiment: DiagnosisSentiment.bearish,
          ));
        }
        if (kNow > 80 && dNow > 80) {
          tags.add(DiagnosisTag(
            emoji: '🚨',
            label: 'KD 高檔鈍化',
            detail: 'K=${kNow.toStringAsFixed(1)} D=${dNow.toStringAsFixed(1)}，過熱',
            sentiment: DiagnosisSentiment.warning,
          ));
        } else if (kNow < 20 && dNow < 20) {
          tags.add(DiagnosisTag(
            emoji: '🟢',
            label: 'KD 低檔鈍化',
            detail: 'K=${kNow.toStringAsFixed(1)} D=${dNow.toStringAsFixed(1)}，超賣',
            sentiment: DiagnosisSentiment.bullish,
          ));
        }
      }
    }

    // 布林通道
    final boll = Indicators.bollinger(candles);
    if (!_anyNaN([boll.upper[last], boll.lower[last], boll.middle[last]])) {
      if (close > boll.upper[last]) {
        tags.add(const DiagnosisTag(
          emoji: '🚀',
          label: '突破布林上軌',
          detail: '價格突破 2 倍標準差，動能強但短線過熱',
          sentiment: DiagnosisSentiment.warning,
        ));
      } else if (close < boll.lower[last]) {
        tags.add(const DiagnosisTag(
          emoji: '🪂',
          label: '跌破布林下軌',
          detail: '價格跌破 2 倍標準差，短線超賣',
          sentiment: DiagnosisSentiment.bullish,
        ));
      }
      final bandwidth =
          (boll.upper[last] - boll.lower[last]) / boll.middle[last] * 100;
      if (bandwidth < 6) {
        tags.add(DiagnosisTag(
          emoji: '🎯',
          label: '布林收斂',
          detail: '通道寬度 ${bandwidth.toStringAsFixed(2)}%，即將變盤',
          sentiment: DiagnosisSentiment.warning,
        ));
      }
    }

    // Williams %R
    final wr = Indicators.williamsR(candles)[last];
    if (!wr.isNaN) {
      if (wr > -20) {
        tags.add(DiagnosisTag(
          emoji: '🔺',
          label: 'W%R 超買',
          detail: '%R = ${wr.toStringAsFixed(1)} (>-20)',
          sentiment: DiagnosisSentiment.warning,
        ));
      } else if (wr < -80) {
        tags.add(DiagnosisTag(
          emoji: '🔻',
          label: 'W%R 超賣',
          detail: '%R = ${wr.toStringAsFixed(1)} (<-80)',
          sentiment: DiagnosisSentiment.bullish,
        ));
      }
    }

    if (tags.isEmpty) {
      tags.add(DiagnosisTag(
        emoji: '⚖️',
        label: '盤整',
        detail: '目前無明顯訊號 (收盤 ${close.toStringAsFixed(2)})',
        sentiment: DiagnosisSentiment.neutral,
      ));
    }
    return tags;
  }

  static bool _anyNaN(List<double> xs) => xs.any((e) => e.isNaN);
}

/// 為 Dashboard sparkline 使用：將近 N 日收盤價標準化
List<double> normalizeCloses(List<Candle> candles, {int? lastN}) {
  if (candles.isEmpty) return const [];
  final data = lastN == null || lastN >= candles.length
      ? candles
      : candles.sublist(candles.length - lastN);
  final closes = data.map((c) => c.close).toList();
  final lo = closes.reduce(math.min);
  final hi = closes.reduce(math.max);
  if (hi == lo) return closes.map((_) => 0.5).toList();
  return closes.map((v) => (v - lo) / (hi - lo)).toList();
}
