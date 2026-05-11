import 'package:flutter_test/flutter_test.dart';
import 'package:fugle_api_app/data/models/candle.dart';
import 'package:fugle_api_app/indicators/pattern_recognition.dart';

Candle _c(int day,
    {double open = 100,
    double high = 101,
    double low = 99,
    double close = 100,
    double vol = 1000}) {
  return Candle(
    date: DateTime(2026, 1, day),
    open: open,
    high: high,
    low: low,
    close: close,
    volume: vol,
  );
}

bool _has(List<CandlePattern> patterns, String name) =>
    patterns.any((p) => p.name.contains(name));

void main() {
  group('PatternRecognition', () {
    test('資料太少回傳空', () {
      final r = PatternRecognition.detect([_c(1), _c(2)]);
      expect(r, isEmpty);
    });

    test('長紅 K 被偵測', () {
      // 先 30 根盤整，最後一根大紅
      final candles = [
        for (var i = 1; i <= 29; i++) _c(i, close: 100),
        _c(30, open: 100, close: 110, high: 110.1, low: 100),
      ];
      final r = PatternRecognition.detect(candles);
      expect(_has(r, '長紅'), isTrue);
    });

    test('長黑 K 被偵測', () {
      final candles = [
        for (var i = 1; i <= 29; i++) _c(i, close: 100),
        _c(30, open: 110, close: 100, high: 110.1, low: 100),
      ];
      final r = PatternRecognition.detect(candles);
      expect(_has(r, '長黑'), isTrue);
    });

    test('十字星 (Doji)', () {
      final candles = [
        for (var i = 1; i <= 29; i++) _c(i, close: 100),
        // 開盤 100, 收盤 100.05, 上下影線各 2
        _c(30, open: 100, close: 100.05, high: 102, low: 98),
      ];
      final r = PatternRecognition.detect(candles);
      expect(_has(r, '十字'), isTrue);
    });

    test('向上跳空被偵測', () {
      final candles = [
        for (var i = 1; i <= 28; i++) _c(i, high: 100, low: 99, close: 99.5),
        // 上一根高點 100
        _c(29, open: 99, high: 100, low: 99, close: 99.5),
        // 今天低點 105 > 昨天高點 100 → 向上跳空 5%
        _c(30, open: 105, high: 108, low: 105, close: 107),
      ];
      final r = PatternRecognition.detect(candles);
      expect(_has(r, '向上跳空'), isTrue);
    });

    test('多頭吞噬', () {
      final candles = [
        for (var i = 1; i <= 28; i++) _c(i, close: 100),
        _c(29, open: 100, close: 98, high: 100.5, low: 97.5), // 黑
        // 今天開盤 < 昨天收盤、今天收盤 > 昨天開盤 → 多頭吞噬
        _c(30, open: 97, close: 101, high: 101.5, low: 97),
      ];
      final r = PatternRecognition.detect(candles);
      expect(_has(r, '多頭吞噬'), isTrue);
    });

    test('空頭吞噬', () {
      final candles = [
        for (var i = 1; i <= 28; i++) _c(i, close: 100),
        _c(29, open: 100, close: 102, high: 102.5, low: 99.5),
        _c(30, open: 103, close: 99, high: 103.5, low: 99),
      ];
      final r = PatternRecognition.detect(candles);
      expect(_has(r, '空頭吞噬'), isTrue);
    });

    test('創 20 日新高', () {
      final candles = [
        for (var i = 1; i <= 20; i++) _c(i, high: 100, low: 99, close: 99.5),
        // 第 21 根收盤超越過去 20 日最高
        _c(21, open: 101, high: 103, low: 101, close: 102.5),
      ];
      final r = PatternRecognition.detect(candles);
      expect(_has(r, '20 日新高'), isTrue);
    });

    test('創 20 日新低', () {
      final candles = [
        for (var i = 1; i <= 20; i++) _c(i, high: 101, low: 100, close: 100.5),
        _c(21, open: 99, high: 99.5, low: 95, close: 95.5),
      ];
      final r = PatternRecognition.detect(candles);
      expect(_has(r, '20 日新低'), isTrue);
    });

    test('每個 pattern 有 emoji + 描述', () {
      final candles = [
        for (var i = 1; i <= 28; i++) _c(i, close: 100),
        _c(29, open: 100, close: 110, high: 110, low: 100), // 長紅
      ];
      final r = PatternRecognition.detect(candles);
      for (final p in r) {
        expect(p.emoji, isNotEmpty);
        expect(p.description, isNotEmpty);
        expect(p.name, isNotEmpty);
      }
    });
  });
}
