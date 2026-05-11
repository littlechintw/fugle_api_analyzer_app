import 'package:flutter_test/flutter_test.dart';
import 'package:fugle_api_app/data/models/candle.dart';
import 'package:fugle_api_app/indicators/indicators.dart';

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
  group('SMA', () {
    test('NaN for first N-1 points then average', () {
      final candles = [
        for (var i = 1; i <= 10; i++) _c(i, i.toDouble()),
      ];
      final sma3 = Indicators.sma(candles, 3);
      expect(sma3[0].isNaN, isTrue);
      expect(sma3[1].isNaN, isTrue);
      expect(sma3[2], closeTo(2.0, 1e-9)); // (1+2+3)/3
      expect(sma3[9], closeTo(9.0, 1e-9)); // (8+9+10)/3
    });

    test('empty / shorter than period returns all NaN', () {
      final empty = <Candle>[];
      expect(Indicators.sma(empty, 5).isEmpty, isTrue);
      final two = [_c(1, 1), _c(2, 2)];
      expect(Indicators.sma(two, 5).every((v) => v.isNaN), isTrue);
    });
  });

  group('BIAS', () {
    test('positive when price above MA', () {
      final candles = [
        for (var i = 1; i <= 30; i++) _c(i, 100.0),
        _c(31, 110), // 第 31 根突然漲到 110
      ];
      final bias = Indicators.bias(candles, 20);
      expect(bias[30], greaterThan(0));
    });
  });

  group('RSI', () {
    test('all rising = RSI 100', () {
      final candles = [
        for (var i = 1; i <= 30; i++) _c(i, i.toDouble()),
      ];
      final rsi = Indicators.rsi(candles, period: 14);
      expect(rsi[14], closeTo(100, 1e-6));
    });

    test('all falling = RSI 0', () {
      final candles = [
        for (var i = 1; i <= 30; i++) _c(i, (40 - i).toDouble()),
      ];
      final rsi = Indicators.rsi(candles, period: 14);
      expect(rsi[14], closeTo(0, 1e-6));
    });
  });

  group('MACD', () {
    test('produces dif/dea/histogram of same length', () {
      final candles = [
        for (var i = 1; i <= 60; i++) _c(i, 50 + i * 0.5),
      ];
      final m = Indicators.macd(candles);
      expect(m.dif.length, candles.length);
      expect(m.dea.length, candles.length);
      expect(m.histogram.length, candles.length);
    });
  });

  group('KD', () {
    test('K and D bounded between 0 and 100', () {
      final candles = [
        for (var i = 1; i <= 30; i++)
          _c(i, 100 + (i % 5) * 2.0,
              high: 100 + (i % 5) * 2.0 + 1,
              low: 100 + (i % 5) * 2.0 - 1),
      ];
      final kd = Indicators.kd(candles);
      for (final k in kd.k) {
        if (k.isNaN) continue;
        expect(k, inInclusiveRange(0, 100));
      }
      for (final d in kd.d) {
        if (d.isNaN) continue;
        expect(d, inInclusiveRange(0, 100));
      }
    });
  });

  group('Bollinger', () {
    test('middle equals SMA, upper > middle > lower', () {
      final candles = [
        for (var i = 1; i <= 30; i++) _c(i, 100 + (i % 7).toDouble()),
      ];
      final boll = Indicators.bollinger(candles, period: 20);
      final sma = Indicators.sma(candles, 20);
      for (var i = 19; i < candles.length; i++) {
        expect(boll.middle[i], closeTo(sma[i], 1e-6));
        expect(boll.upper[i], greaterThanOrEqualTo(boll.middle[i]));
        expect(boll.lower[i], lessThanOrEqualTo(boll.middle[i]));
      }
    });
  });

  group('OBV', () {
    test('rises with bullish candles', () {
      final candles = [
        for (var i = 1; i <= 5; i++) _c(i, 100.0 + i, vol: 1000),
      ];
      final obv = Indicators.obv(candles);
      expect(obv.last > obv.first, isTrue);
    });

    test('falls with bearish candles', () {
      final candles = [
        for (var i = 1; i <= 5; i++) _c(i, 100.0 - i, vol: 1000),
      ];
      final obv = Indicators.obv(candles);
      expect(obv.last < obv.first, isTrue);
    });
  });

  group('ATR', () {
    test('non-negative, NaN before period', () {
      final candles = [
        for (var i = 1; i <= 30; i++)
          _c(i, 100.0 + i,
              high: 100.0 + i + 2, low: 100.0 + i - 2),
      ];
      final atr = Indicators.atr(candles);
      for (var i = 0; i < 14; i++) {
        expect(atr[i].isNaN, isTrue);
      }
      for (var i = 14; i < candles.length; i++) {
        expect(atr[i], greaterThan(0));
      }
    });
  });

  group('Williams %R', () {
    test('bounded in [-100, 0]', () {
      final candles = [
        for (var i = 1; i <= 30; i++)
          _c(i, 100.0 + (i % 7),
              high: 105 + (i % 7).toDouble(), low: 95 + (i % 7).toDouble()),
      ];
      final wr = Indicators.williamsR(candles);
      for (final v in wr) {
        if (v.isNaN) continue;
        expect(v, inInclusiveRange(-100, 0));
      }
    });
  });

  // ============== 邊界 / 退化 case ==============
  group('邊界 case', () {
    test('SMA period == 1 → 每點等於 close', () {
      final candles = [_c(1, 100), _c(2, 200), _c(3, 300)];
      final sma = Indicators.sma(candles, 1);
      expect(sma[0], 100);
      expect(sma[1], 200);
      expect(sma[2], 300);
    });

    test('SMA period == 0 → 全 NaN', () {
      final candles = [_c(1, 100), _c(2, 200)];
      final sma = Indicators.sma(candles, 0);
      expect(sma.every((v) => v.isNaN), isTrue);
    });

    test('RSI 上漲下跌交錯不爆炸', () {
      final candles = <Candle>[];
      for (var i = 1; i <= 30; i++) {
        candles.add(_c(i, i.isEven ? 100 : 110));
      }
      final rsi = Indicators.rsi(candles);
      for (final v in rsi.skip(14)) {
        expect(v, inInclusiveRange(0, 100));
      }
    });

    test('Bollinger 全部相同價格 → upper = middle = lower', () {
      final candles = [
        for (var i = 1; i <= 30; i++) _c(i, 100, high: 100, low: 100),
      ];
      final b = Indicators.bollinger(candles);
      for (var i = 19; i < candles.length; i++) {
        expect(b.upper[i], closeTo(b.middle[i], 1e-6));
        expect(b.lower[i], closeTo(b.middle[i], 1e-6));
      }
    });

    test('OBV 同價格時不變', () {
      final candles = [
        for (var i = 1; i <= 5; i++) _c(i, 100, vol: 1000),
      ];
      final obv = Indicators.obv(candles);
      // close 都相同 → diff == 0 → 不加不減
      expect(obv.first, 0);
      expect(obv.last, 0);
    });

    test('ATR 在週期內全部 NaN', () {
      final candles = [
        for (var i = 1; i <= 14; i++) _c(i, 100, high: 102, low: 98),
      ];
      final atr = Indicators.atr(candles);
      for (var i = 0; i < 14; i++) {
        expect(atr[i].isNaN, isTrue);
      }
    });

    test('Williams %R 高低相同 → 預設 -50', () {
      final candles = [
        for (var i = 1; i <= 20; i++) _c(i, 100, high: 100, low: 100),
      ];
      final wr = Indicators.williamsR(candles);
      // 高低相同會用 -50 fallback
      for (var i = 13; i < candles.length; i++) {
        expect(wr[i], -50);
      }
    });

    test('KD 初始狀態 prevK = prevD = 50', () {
      // 只有剛好 period 根時，第一個 KD 值會基於 prevK=50, prevD=50 算
      final candles = [
        for (var i = 1; i <= 9; i++)
          _c(i, 100, high: 105, low: 95),
      ];
      final kd = Indicators.kd(candles, period: 9);
      // 第 9 根有值
      expect(kd.k[8].isNaN, isFalse);
      expect(kd.d[8].isNaN, isFalse);
    });
  });
}
