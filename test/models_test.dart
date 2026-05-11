import 'package:flutter_test/flutter_test.dart';
import 'package:fugle_api_app/data/models/candle.dart';
import 'package:fugle_api_app/data/models/capital_change.dart';
import 'package:fugle_api_app/data/models/dividend.dart';
import 'package:fugle_api_app/data/models/fundamental.dart';
import 'package:fugle_api_app/data/models/historical_stats.dart';
import 'package:fugle_api_app/data/models/holding.dart';
import 'package:fugle_api_app/data/models/intraday_candle.dart';
import 'package:fugle_api_app/data/models/intraday_trade.dart';
import 'package:fugle_api_app/data/models/market_mover.dart';
import 'package:fugle_api_app/data/models/order_book.dart';
import 'package:fugle_api_app/data/models/price_alert.dart';
import 'package:fugle_api_app/data/models/price_volume.dart';
import 'package:fugle_api_app/data/models/stock_quote.dart';

void main() {
  group('Candle', () {
    test('fromFugleHistorical 正確解析', () {
      final c = Candle.fromFugleHistorical({
        'date': '2026-05-08',
        'open': 100.5,
        'high': 105.0,
        'low': 99.0,
        'close': 104.0,
        'volume': 12345,
      });
      expect(c.open, 100.5);
      expect(c.close, 104.0);
      expect(c.isBullish, isTrue);
      expect(c.date.year, 2026);
      expect(c.date.month, 5);
      expect(c.date.day, 8);
    });

    test('isBullish: open == close 視為紅 K', () {
      final c = Candle(
        date: DateTime(2026),
        open: 100,
        high: 100,
        low: 100,
        close: 100,
        volume: 0,
      );
      expect(c.isBullish, isTrue);
    });

    test('toMap / fromMap 對稱', () {
      final c = Candle(
        date: DateTime(2026, 5, 11),
        open: 50,
        high: 55,
        low: 49,
        close: 54,
        volume: 100,
      );
      final round = Candle.fromMap(c.toMap());
      expect(round.open, c.open);
      expect(round.close, c.close);
      expect(round.date, c.date);
    });
  });

  group('IntradayCandle', () {
    test('時間從 +08:00 字串轉為本地時間', () {
      final ic = IntradayCandle.fromFugle({
        'date': '2026-05-11T09:00:00.000+08:00',
        'open': 600.0,
        'high': 605.0,
        'low': 599.0,
        'close': 603.0,
        'volume': 1000,
        'average': 601.5,
      });
      expect(ic.open, 600);
      expect(ic.average, 601.5);
      // 時間經 toLocal()，預期 hour 應該是 9（若裝置時區為 +08:00）
      // 不嚴格比較 hour，避免 CI 在 UTC 環境跑出不一樣
      expect(ic.time.isUtc, isFalse);
    });

    test('沒有 average 時可選欄位為 null', () {
      final ic = IntradayCandle.fromFugle({
        'date': '2026-05-11T09:00:00.000+08:00',
        'open': 1,
        'high': 1,
        'low': 1,
        'close': 1,
      });
      expect(ic.volume, 0);
      expect(ic.average, isNull);
    });
  });

  group('IntradayTrade', () {
    test('微秒時間戳 + isBuy / isSell 判斷', () {
      final t = IntradayTrade.fromFugle({
        'price': 100,
        'size': 50,
        'bid': 99.5,
        'ask': 100.0,
        'time': 1700000000000000, // microseconds
        'serial': 12345,
      });
      expect(t.price, 100);
      expect(t.size, 50);
      expect(t.isBuy, isTrue); // 成交 = ask
      expect(t.isSell, isFalse);
    });

    test('成交價在 bid → 主動賣', () {
      final t = IntradayTrade.fromFugle({
        'price': 99.5,
        'size': 10,
        'bid': 99.5,
        'ask': 100.0,
        'time': 0,
        'serial': 1,
      });
      expect(t.isSell, isTrue);
      expect(t.isBuy, isFalse);
    });
  });

  group('PriceVolume', () {
    test('正常解析', () {
      final p = PriceVolume.fromFugle({
        'price': 87.5,
        'volume': 10000,
        'volumeAtBid': 3000,
        'volumeAtAsk': 7000,
      });
      expect(p.price, 87.5);
      expect(p.volume, 10000);
      expect(p.volumeAtBid + p.volumeAtAsk, 10000);
    });
  });

  group('OrderBook', () {
    test('五檔 + 內外盤量', () {
      final ob = OrderBookSnapshot.fromFugleQuote('2330', {
        'bids': [
          {'price': 599, 'size': 100},
          {'price': 598, 'size': 200},
        ],
        'asks': [
          {'price': 600, 'size': 150},
          {'price': 601, 'size': 250},
        ],
        'total': {
          'tradeVolumeAtBid': 400,
          'tradeVolumeAtAsk': 600,
        },
      });
      expect(ob.bids.length, 2);
      expect(ob.bids.first.price, 599);
      expect(ob.asks.first.size, 150);
      expect(ob.bidRatio, closeTo(0.4, 1e-9));
      expect(ob.askRatio, closeTo(0.6, 1e-9));
    });

    test('內外盤都 0 時 bidRatio 返回 0.5', () {
      final ob = OrderBookSnapshot.fromFugleQuote('X', {
        'bids': [],
        'asks': [],
        'total': {},
      });
      expect(ob.bidRatio, 0.5);
    });
  });

  group('StockQuote', () {
    test('正常解析 + 補算 change/changePercent', () {
      final q = StockQuote.fromFugleQuote({
        'symbol': '2330',
        'lastPrice': 600,
        'previousClose': 590,
      });
      // change 應該被算出來 (600-590=10)
      expect(q.lastPrice, 600);
      expect(q.previousClose, 590);
      expect(q.change, closeTo(10, 1e-9));
      expect(q.changePercent, closeTo(10 / 590 * 100, 1e-6));
    });

    test('沒提供 previousClose 也不會壞', () {
      final q = StockQuote.fromFugleQuote({
        'symbol': '2330',
        'lastPrice': 600,
      });
      expect(q.lastPrice, 600);
    });
  });

  group('HistoricalStats', () {
    test('52 週區間位置與距離計算', () {
      final s = HistoricalStats.fromFugle({
        'symbol': '2330',
        'closePrice': 75,
        'week52High': 100,
        'week52Low': 50,
      });
      expect(s.rangePosition(), closeTo(0.5, 1e-9));
      expect(s.distanceFromHighPct(), closeTo(-25, 1e-6));
      expect(s.distanceFromLowPct(), closeTo(50, 1e-6));
    });

    test('區間為 0 時不爆炸', () {
      final s = HistoricalStats.fromFugle({
        'symbol': 'X',
        'closePrice': 100,
        'week52High': 0,
        'week52Low': 0,
      });
      expect(s.rangePosition(), 0.5);
      expect(s.distanceFromHighPct(), 0);
    });
  });

  group('Dividend', () {
    test('現金殖利率以前一日收盤計', () {
      final d = Dividend.fromFugle({
        'date': '2025-08-26',
        'symbol': '2330',
        'name': '台積電',
        'cashDividend': 5.0,
        'previousClose': 100.0,
        'dividend': 5.0,
        'dividendType': '息',
      });
      expect(d.cashYield, closeTo(5.0, 1e-9));
      expect(d.isFuture, isFalse);
    });

    test('未來除權息日標記 isFuture', () {
      final future = DateTime.now().add(const Duration(days: 30));
      final d = Dividend.fromFugle({
        'date': future.toIso8601String().split('T').first,
        'symbol': 'X',
        'name': 'X',
        'cashDividend': 1.0,
        'dividend': 1.0,
        'dividendType': '息',
      });
      expect(d.isFuture, isTrue);
      expect(d.cashYield, isNull);
    });
  });

  group('CapitalChange', () {
    test('減資解析 + displayLabel', () {
      final c = CapitalChange.fromFugle({
        'symbol': '8103',
        'name': '瀚荃',
        'actionType': 'capital_reduction',
        'resumeDate': '2025-12-08',
        'haltDate': '2025-11-27',
        'raw': {
          'reason': '退還股款',
          'refundPerShare': 1.5,
          'previousClose': 74.7,
          'referencePrice': 86.11,
        },
      });
      expect(c.displayLabel, '減資');
      expect(c.refundPerShare, 1.5);
    });

    test('ETF 反分割 displayLabel', () {
      final c = CapitalChange.fromFugle({
        'symbol': '00715L',
        'name': '某 ETF',
        'actionType': 'etf_split_or_merge',
        'raw': {'splitType': '反分割'},
      });
      expect(c.displayLabel, 'ETF 反分割');
    });
  });

  group('Fundamental', () {
    test('解析 + 空字串 / 連字號變 null', () {
      final f = FundamentalSnapshot.fromTwse('2330', {
        'PEratio': '23.45',
        'PBratio': '-',
        'DividendYield': '2.10',
        'FinancialReportYear': '2024',
      });
      expect(f.peRatio, 23.45);
      expect(f.pbRatio, isNull);
      expect(f.dividendYield, 2.1);
      expect(f.dividendYear, '2024');
      expect(f.isEmpty, isFalse);
    });

    test('全部缺值 → isEmpty', () {
      final f = FundamentalSnapshot.fromTwse('X', {});
      expect(f.isEmpty, isTrue);
    });
  });

  group('MarketMover', () {
    test('完整解析', () {
      final m = MarketMover.fromFugle({
        'symbol': '2330',
        'name': '台積電',
        'openPrice': 600,
        'highPrice': 610,
        'lowPrice': 595,
        'closePrice': 605,
        'change': 5,
        'changePercent': 0.83,
        'tradeVolume': 12345,
        'tradeValue': 7500000000,
      });
      expect(m.symbol, '2330');
      expect(m.change, 5);
      expect(m.tradeValue, 7500000000);
    });
  });

  group('Holding', () {
    test('損益計算', () {
      final h = Holding(
        symbol: '2330',
        name: '台積電',
        quantity: 1000,
        avgCost: 500,
        addedAt: DateTime(2025, 1, 1),
      );
      expect(h.costBasis, 500000);
      expect(h.marketValue(600), 600000);
      expect(h.unrealizedPnL(600), 100000);
      expect(h.unrealizedPct(600), closeTo(20, 1e-9));
    });

    test('avgCost 0 不會除以零', () {
      final h = Holding(
        symbol: 'X',
        name: 'X',
        quantity: 100,
        avgCost: 0,
        addedAt: DateTime(2025),
      );
      expect(h.unrealizedPct(50), 0);
    });

    test('copyWith 保留 symbol/name/addedAt', () {
      final h = Holding(
        symbol: '2330',
        name: '台積電',
        quantity: 1000,
        avgCost: 500,
        addedAt: DateTime(2025),
      );
      final h2 = h.copyWith(quantity: 2000, avgCost: 550);
      expect(h2.symbol, '2330');
      expect(h2.quantity, 2000);
      expect(h2.avgCost, 550);
      expect(h2.addedAt, h.addedAt);
    });
  });

  group('PriceAlert', () {
    test('觸發條件 (above)', () {
      final a = PriceAlert(
        id: 'x',
        symbol: '2330',
        name: '台積電',
        direction: AlertDirection.above,
        price: 600,
        createdAt: DateTime(2026),
      );
      expect(a.isTriggered(600), isTrue);
      expect(a.isTriggered(599), isFalse);
      expect(a.isTriggered(700), isTrue);
    });

    test('觸發條件 (below)', () {
      final a = PriceAlert(
        id: 'x',
        symbol: '2330',
        name: '台積電',
        direction: AlertDirection.below,
        price: 500,
        createdAt: DateTime(2026),
      );
      expect(a.isTriggered(500), isTrue);
      expect(a.isTriggered(501), isFalse);
      expect(a.isTriggered(400), isTrue);
    });

    test('停用警示不觸發', () {
      final a = PriceAlert(
        id: 'x',
        symbol: '2330',
        name: 'X',
        direction: AlertDirection.above,
        price: 100,
        createdAt: DateTime(2026),
        enabled: false,
      );
      expect(a.isTriggered(200), isFalse);
    });

    test('makeId 含方向與價格', () {
      final id =
          PriceAlert.makeId('2330', AlertDirection.above, 600.0);
      expect(id, contains('2330'));
      expect(id, contains('above'));
      expect(id, contains('600'));
    });
  });
}
