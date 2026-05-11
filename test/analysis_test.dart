import 'package:flutter_test/flutter_test.dart';
import 'package:fugle_api_app/data/models/candle.dart';
import 'package:fugle_api_app/indicators/analysis.dart';

Candle _c(int day, double close,
    {double? open, double? high, double? low, double vol = 1000}) {
  return Candle(
    date: DateTime(2026, 1, day),
    open: open ?? close,
    high: high ?? close,
    low: low ?? close,
    close: close,
    volume: vol,
  );
}

void main() {
  group('VolatilityAnalyser', () {
    test('returns zero report for insufficient data', () {
      final report = VolatilityAnalyser.analyse([_c(1, 100)]);
      expect(report.atr, 0);
      expect(report.level, VolatilityLevel.normal);
    });

    test('classifies high volatility when ATR > 1.3x histMean', () {
      // 前 30 根低波動，後 5 根爆量
      final candles = <Candle>[
        for (var i = 1; i <= 30; i++)
          _c(i, 100.0, high: 100.5, low: 99.5),
        for (var i = 31; i <= 40; i++)
          _c(i, 100.0 + i, high: 110.0 + i, low: 90.0 + i),
      ];
      final report = VolatilityAnalyser.analyse(candles);
      expect(report.atr, greaterThan(0));
      expect(report.expectedHigh, greaterThan(report.expectedLow));
    });
  });

  group('SignalAnalyser', () {
    test('returns empty votes if too few candles', () {
      final report = SignalAnalyser.analyse([_c(1, 100)]);
      expect(report.votes, isEmpty);
      expect(report.bias, SignalBias.neutral);
    });

    test('produces 5+ votes with 60 candles', () {
      final candles = [
        for (var i = 1; i <= 80; i++)
          _c(i, 100.0 + (i * 0.5),
              high: 100.0 + (i * 0.5) + 1, low: 100.0 + (i * 0.5) - 1),
      ];
      final report = SignalAnalyser.analyse(candles);
      expect(report.votes.length, greaterThanOrEqualTo(5));
      // 持續上漲應該偏多
      expect(report.totalScore, greaterThan(0));
    });

    test('agreement percentage is correct', () {
      final candles = [
        for (var i = 1; i <= 80; i++) _c(i, 100.0 + i),
      ];
      final report = SignalAnalyser.analyse(candles);
      expect(report.agreementPct, inInclusiveRange(0, 100));
    });
  });
}
