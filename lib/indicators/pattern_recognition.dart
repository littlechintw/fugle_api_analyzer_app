import 'dart:math' as math;

import '../data/models/candle.dart';

/// 偵測到的 K 線型態
class CandlePattern {
  final int index;         // 在 candles 陣列中的位置
  final String name;       // 型態中文名
  final String emoji;
  final String description;
  final PatternBias bias;
  const CandlePattern({
    required this.index,
    required this.name,
    required this.emoji,
    required this.description,
    required this.bias,
  });
}

enum PatternBias { bullish, bearish, neutral }

class PatternRecognition {
  /// 掃描整個序列，回傳偵測到的所有型態。
  /// 重點掃描最後 30 根 (太遠的型態參考價值低)。
  static List<CandlePattern> detect(List<Candle> candles) {
    final out = <CandlePattern>[];
    if (candles.length < 5) return out;
    final start = math.max(2, candles.length - 30);

    for (var i = start; i < candles.length; i++) {
      _detectSingleCandle(candles, i, out);
    }
    _detectPairPatterns(candles, start, out);
    _detectGap(candles, start, out);
    _detectDoubleTopBottom(candles, out);
    _detectBreakout(candles, out);

    // 同位置同名只留一個
    final seen = <String>{};
    return out.where((p) {
      final k = '${p.index}-${p.name}';
      if (seen.contains(k)) return false;
      seen.add(k);
      return true;
    }).toList();
  }

  // -------- 單根 K 棒型態 --------
  static void _detectSingleCandle(
      List<Candle> candles, int i, List<CandlePattern> out) {
    final c = candles[i];
    final body = (c.close - c.open).abs();
    final range = c.high - c.low;
    if (range == 0) return;
    final bodyRatio = body / range;
    final upperShadow = c.high - math.max(c.open, c.close);
    final lowerShadow = math.min(c.open, c.close) - c.low;

    // 十字星 (Doji): 實體 < 10% 全幅
    if (bodyRatio < 0.1 && range > 0) {
      out.add(CandlePattern(
        index: i,
        name: '十字星 Doji',
        emoji: '✚',
        description: '開收幾乎相同，多空拉鋸',
        bias: PatternBias.neutral,
      ));
    }
    // 鎚子 / 吊人線：實體小、下影線長、上影線短
    if (lowerShadow > body * 2 && upperShadow < body * 0.3 && body > 0) {
      // 之前是下跌 → 鎚子 (反轉看多)
      if (i >= 3 && candles[i - 1].close < candles[i - 3].close) {
        out.add(CandlePattern(
          index: i,
          name: '鎚子線',
          emoji: '🔨',
          description: '下跌途中長下影線，可能止跌',
          bias: PatternBias.bullish,
        ));
      } else if (i >= 3 && candles[i - 1].close > candles[i - 3].close) {
        out.add(CandlePattern(
          index: i,
          name: '吊人線',
          emoji: '⚠️',
          description: '上漲途中長下影線，警示反轉',
          bias: PatternBias.bearish,
        ));
      }
    }
    // 流星 / 倒鎚：上影線長
    if (upperShadow > body * 2 && lowerShadow < body * 0.3 && body > 0) {
      if (i >= 3 && candles[i - 1].close > candles[i - 3].close) {
        out.add(CandlePattern(
          index: i,
          name: '流星線',
          emoji: '☄️',
          description: '上漲途中長上影線，賣壓出現',
          bias: PatternBias.bearish,
        ));
      } else if (i >= 3 && candles[i - 1].close < candles[i - 3].close) {
        out.add(CandlePattern(
          index: i,
          name: '倒鎚線',
          emoji: '🔧',
          description: '下跌途中長上影線，可能止跌',
          bias: PatternBias.bullish,
        ));
      }
    }
    // 大紅 / 大黑棒
    if (bodyRatio > 0.85 && body / c.close > 0.04) {
      if (c.isBullish) {
        out.add(CandlePattern(
          index: i,
          name: '長紅 K',
          emoji: '🚀',
          description: '實體佔 85%+ 全幅，買盤強勢',
          bias: PatternBias.bullish,
        ));
      } else {
        out.add(CandlePattern(
          index: i,
          name: '長黑 K',
          emoji: '🪂',
          description: '實體佔 85%+ 全幅，賣壓沉重',
          bias: PatternBias.bearish,
        ));
      }
    }
  }

  // -------- 兩根 K 棒型態 (吞噬、孕線、貫穿) --------
  static void _detectPairPatterns(
      List<Candle> candles, int from, List<CandlePattern> out) {
    for (var i = from + 1; i < candles.length; i++) {
      final p = candles[i - 1];
      final c = candles[i];
      // 多頭吞噬
      if (!p.isBullish &&
          c.isBullish &&
          c.open < p.close &&
          c.close > p.open) {
        out.add(CandlePattern(
          index: i,
          name: '多頭吞噬',
          emoji: '🐂',
          description: '前黑棒被當日紅棒完全吞噬',
          bias: PatternBias.bullish,
        ));
      }
      // 空頭吞噬
      if (p.isBullish &&
          !c.isBullish &&
          c.open > p.close &&
          c.close < p.open) {
        out.add(CandlePattern(
          index: i,
          name: '空頭吞噬',
          emoji: '🐻',
          description: '前紅棒被當日黑棒完全吞噬',
          bias: PatternBias.bearish,
        ));
      }
    }
  }

  // -------- 缺口偵測 --------
  static void _detectGap(
      List<Candle> candles, int from, List<CandlePattern> out) {
    for (var i = from; i < candles.length; i++) {
      final p = candles[i - 1];
      final c = candles[i];
      // 向上跳空 (今天低點 > 昨天高點)
      if (c.low > p.high) {
        final gapPct = (c.low - p.high) / p.high * 100;
        if (gapPct > 1) {
          out.add(CandlePattern(
            index: i,
            name: '向上跳空',
            emoji: '⤴️',
            description: '跳空 ${gapPct.toStringAsFixed(2)}%，動能強',
            bias: PatternBias.bullish,
          ));
        }
      }
      // 向下跳空
      if (c.high < p.low) {
        final gapPct = (p.low - c.high) / p.low * 100;
        if (gapPct > 1) {
          out.add(CandlePattern(
            index: i,
            name: '向下跳空',
            emoji: '⤵️',
            description: '跳空 ${gapPct.toStringAsFixed(2)}%，賣壓重',
            bias: PatternBias.bearish,
          ));
        }
      }
    }
  }

  // -------- 雙底 / 雙頂 (簡化版：在最後 20 根內找兩個相近極值) --------
  static void _detectDoubleTopBottom(
      List<Candle> candles, List<CandlePattern> out) {
    if (candles.length < 20) return;
    final start = math.max(0, candles.length - 30);
    final tail = candles.sublist(start);
    final last = candles.length - 1;
    // 找出最低與次低
    int lo1 = 0, lo2 = -1;
    for (var i = 1; i < tail.length; i++) {
      if (tail[i].low < tail[lo1].low) {
        lo2 = lo1;
        lo1 = i;
      }
    }
    if (lo2 >= 0) {
      final l1 = tail[lo1].low;
      final l2 = tail[lo2].low;
      final diffPct = (l2 - l1).abs() / l1 * 100;
      final distance = (lo1 - lo2).abs();
      if (diffPct < 2 && distance >= 5 && distance <= 25) {
        // 雙底，且當前價已脫離低點
        final currentPrice = tail.last.close;
        if (currentPrice > l1 * 1.03) {
          out.add(CandlePattern(
            index: last,
            name: '雙底 W',
            emoji: '🅆',
            description: '近期出現兩個相近低點，可能止跌反轉',
            bias: PatternBias.bullish,
          ));
        }
      }
    }
    // 雙頂 (M 頭)
    int hi1 = 0, hi2 = -1;
    for (var i = 1; i < tail.length; i++) {
      if (tail[i].high > tail[hi1].high) {
        hi2 = hi1;
        hi1 = i;
      }
    }
    if (hi2 >= 0) {
      final h1 = tail[hi1].high;
      final h2 = tail[hi2].high;
      final diffPct = (h2 - h1).abs() / h1 * 100;
      final distance = (hi1 - hi2).abs();
      if (diffPct < 2 && distance >= 5 && distance <= 25) {
        final currentPrice = tail.last.close;
        if (currentPrice < h1 * 0.97) {
          out.add(CandlePattern(
            index: last,
            name: '雙頂 M',
            emoji: '🅼',
            description: '近期出現兩個相近高點，可能反轉下跌',
            bias: PatternBias.bearish,
          ));
        }
      }
    }
  }

  // -------- 突破 / 跌破 (20 日新高/新低) --------
  static void _detectBreakout(
      List<Candle> candles, List<CandlePattern> out) {
    if (candles.length < 21) return;
    final last = candles.length - 1;
    final window = candles.sublist(candles.length - 21, candles.length - 1);
    final hi = window.map((c) => c.high).reduce((a, b) => a > b ? a : b);
    final lo = window.map((c) => c.low).reduce((a, b) => a < b ? a : b);
    if (candles[last].close > hi) {
      out.add(CandlePattern(
        index: last,
        name: '創 20 日新高',
        emoji: '🏔',
        description: '突破近 20 日壓力區',
        bias: PatternBias.bullish,
      ));
    }
    if (candles[last].close < lo) {
      out.add(CandlePattern(
        index: last,
        name: '創 20 日新低',
        emoji: '⛓',
        description: '跌破近 20 日支撐區',
        bias: PatternBias.bearish,
      ));
    }
  }
}
