import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fugle_api_app/data/models/api_log.dart';
import 'package:fugle_api_app/data/models/candle.dart';
import 'package:fugle_api_app/data/models/dividend.dart';
import 'package:fugle_api_app/data/models/holding.dart';
import 'package:fugle_api_app/data/models/intraday_trade.dart';
import 'package:fugle_api_app/data/models/market_mover.dart';
import 'package:fugle_api_app/data/models/price_alert.dart';
import 'package:fugle_api_app/data/models/stock_quote.dart';
import 'package:fugle_api_app/data/models/ticker.dart';
import 'package:fugle_api_app/data/models/watchlist_group.dart';
import 'package:fugle_api_app/data/providers/watchlist_group_provider.dart';
import 'package:fugle_api_app/data/services/api_log_interceptor.dart';
import 'package:fugle_api_app/data/services/hive_service.dart';

import '_hive_helper.dart';

void main() {
  setUpAll(setupHiveForTesting);
  tearDownAll(teardownHive);
  setUp(resetHiveBoxes);

  // ============== 加 Model factory 邊界 case ==============

  group('Ticker.fromFugle', () {
    test('完整解析', () {
      final t = Ticker.fromFugle({
        'symbol': '2330',
        'name': '台積電',
        'exchange': 'TWSE',
        'market': 'TSE',
      });
      expect(t.symbol, '2330');
      expect(t.name, '台積電');
      expect(t.exchange, 'TWSE');
      expect(t.market, 'TSE');
    });

    test('缺欄位回空字串不爆炸', () {
      final t = Ticker.fromFugle({});
      expect(t.symbol, '');
      expect(t.name, '');
      expect(t.exchange, '');
      expect(t.market, '');
    });
  });

  group('StockQuote.fromFugleQuote 邊界', () {
    test('字串型別的數字被解析', () {
      final q = StockQuote.fromFugleQuote({
        'symbol': '2330',
        'lastPrice': '600',
        'previousClose': '590',
      });
      expect(q.lastPrice, 600);
      expect(q.previousClose, 590);
    });

    test('null 數字欄位變成 0', () {
      final q = StockQuote.fromFugleQuote({
        'symbol': '2330',
        'lastPrice': null,
      });
      expect(q.lastPrice, 0);
      expect(q.change, 0);
    });

    test('使用 symbolId 替代 symbol', () {
      final q = StockQuote.fromFugleQuote({
        'symbolId': '2330',
        'lastPrice': 600,
      });
      expect(q.symbol, '2330');
    });

    test('使用 closePrice 替代 lastPrice', () {
      final q = StockQuote.fromFugleQuote({
        'symbol': '2330',
        'closePrice': 555,
        'referencePrice': 550,
      });
      expect(q.lastPrice, 555);
      expect(q.previousClose, 550);
    });

    test('total.tradeVolume 巢狀解析', () {
      final q = StockQuote.fromFugleQuote({
        'symbol': '2330',
        'lastPrice': 600,
        'total': {'tradeVolume': 1234567},
      });
      expect(q.volume, 1234567);
    });

    test('直接的 change/changePercent 不被覆蓋', () {
      final q = StockQuote.fromFugleQuote({
        'symbol': '2330',
        'lastPrice': 600,
        'previousClose': 590,
        'change': 8.5,
        'changePercent': 1.44,
      });
      expect(q.change, 8.5);
      expect(q.changePercent, 1.44);
    });
  });

  group('IntradayTrade 邊界', () {
    test('bid == null 不會誤判 isBuy/isSell', () {
      final t = IntradayTrade.fromFugle({
        'price': 100,
        'size': 10,
        'time': 0,
        'serial': 1,
      });
      expect(t.isBuy, isFalse);
      expect(t.isSell, isFalse);
    });

    test('字串型別欄位也能解析', () {
      final t = IntradayTrade.fromFugle({
        'price': '99.5',
        'size': '20',
        'bid': '99',
        'ask': '99.5',
        'time': '1234567890',
        'serial': '999',
      });
      expect(t.price, 99.5);
      expect(t.size, 20);
      expect(t.serial, 999);
    });
  });

  group('MarketMover 邊界', () {
    test('字串型別的 number 也能解析', () {
      final m = MarketMover.fromFugle({
        'symbol': '2330',
        'name': '台積電',
        'closePrice': '600',
        'change': '5',
      });
      expect(m.closePrice, 600);
      expect(m.change, 5);
    });

    test('缺欄位填 0', () {
      final m = MarketMover.fromFugle({});
      expect(m.symbol, '');
      expect(m.closePrice, 0);
    });
  });

  group('Candle 邊界', () {
    test('fromMap 對於缺欄位會丟例外（型別假設）', () {
      // 應該丟錯，因為 'open' is required (as num)
      expect(
        () => Candle.fromMap({'date': '2026-05-08'}),
        throwsA(isA<TypeError>()),
      );
    });

    test('isBullish: close > open', () {
      final c = Candle(
        date: DateTime(2026),
        open: 100,
        high: 102,
        low: 99,
        close: 101,
        volume: 1,
      );
      expect(c.isBullish, isTrue);
    });

    test('isBullish: close < open → false', () {
      final c = Candle(
        date: DateTime(2026),
        open: 100,
        high: 100,
        low: 98,
        close: 98,
        volume: 1,
      );
      expect(c.isBullish, isFalse);
    });
  });

  group('PriceAlert 邊界', () {
    test('copyWith 不傳 lastTriggeredAt 仍會帶上舊值', () {
      final base = PriceAlert(
        id: 'x',
        symbol: '2330',
        name: 'X',
        direction: AlertDirection.above,
        price: 100,
        createdAt: DateTime(2026),
        lastTriggeredAt: DateTime(2026, 5, 1),
      );
      final c = base.copyWith(enabled: false);
      expect(c.enabled, isFalse);
      expect(c.lastTriggeredAt, DateTime(2026, 5, 1)); // 保留
    });

    test('directionLabel 雙向都有值', () {
      final a1 = PriceAlert(
        id: 'a',
        symbol: 'X',
        name: 'X',
        direction: AlertDirection.above,
        price: 1,
        createdAt: DateTime(2026),
      );
      final a2 = PriceAlert(
        id: 'b',
        symbol: 'X',
        name: 'X',
        direction: AlertDirection.below,
        price: 1,
        createdAt: DateTime(2026),
      );
      expect(a1.directionLabel, '高於');
      expect(a2.directionLabel, '低於');
    });
  });

  group('Holding 邊界', () {
    test('quantity 為 0 → costBasis 與 marketValue 都是 0', () {
      final h = Holding(
        symbol: 'X',
        name: 'X',
        quantity: 0,
        avgCost: 100,
        addedAt: DateTime(2025),
      );
      expect(h.costBasis, 0);
      expect(h.marketValue(50), 0);
    });

    test('未實現損益為負值', () {
      final h = Holding(
        symbol: 'X',
        name: 'X',
        quantity: 100,
        avgCost: 100,
        addedAt: DateTime(2025),
      );
      expect(h.unrealizedPnL(80), -2000);
      expect(h.unrealizedPct(80), closeTo(-20, 1e-9));
    });
  });

  group('Dividend 邊界', () {
    test('previousClose null → cashYield = null', () {
      final d = Dividend.fromFugle({
        'date': '2026-01-08',
        'symbol': 'X',
        'name': 'X',
        'cashDividend': 5.0,
        'dividend': 5.0,
        'dividendType': '息',
      });
      expect(d.cashYield, isNull);
    });

    test('previousClose = 0 → cashYield = null', () {
      final d = Dividend.fromFugle({
        'date': '2026-01-08',
        'symbol': 'X',
        'name': 'X',
        'cashDividend': 5.0,
        'previousClose': 0,
        'dividend': 5.0,
        'dividendType': '息',
      });
      expect(d.cashYield, isNull);
    });
  });

  group('WatchlistGroup 邊界', () {
    test('allGroupId 常數正確', () {
      expect(WatchlistGroup.allGroupId, '__all__');
    });
  });

  // ============== Notifier 剩餘方法 ==============

  group('WatchlistGroupNotifier.selectGroup', () {
    test('selectGroup 持久化目前選擇', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final n = c.read(watchlistGroupsProvider.notifier);

      expect(n.currentSelected(), WatchlistGroup.allGroupId);
      n.create('A', 0);
      final gid = c.read(watchlistGroupsProvider).first.id;

      n.selectGroup(gid);
      expect(n.currentSelected(), gid);
    });
  });

  // ============== ApiLogInterceptor（用 Dio MockAdapter）==============

  group('ApiLogInterceptor', () {
    test('成功請求會寫入 success log + 觸發 start/end 回呼', () async {
      var starts = 0;
      var ends = 0;
      final dio = Dio()
        ..httpClientAdapter = _StubAdapter(200, '{"ok":true}')
        ..interceptors.add(ApiLogInterceptor(
          HiveService.instance,
          onRequestStart: () => starts++,
          onRequestEnd: () => ends++,
        ));

      await dio.get<dynamic>('http://example.com/x');

      expect(starts, 1);
      expect(ends, 1);
      final logs = HiveService.instance.apiLogs.values.toList();
      expect(logs.length, 1);
      expect(logs.first.success, isTrue);
      expect(logs.first.statusCode, 200);
      expect(logs.first.method, 'GET');
    });

    test('失敗請求會寫入 failure log + 仍觸發 end 回呼', () async {
      var ends = 0;
      final dio = Dio()
        ..httpClientAdapter = _StubAdapter(404, '{"error":"nope"}')
        ..interceptors.add(ApiLogInterceptor(
          HiveService.instance,
          onRequestEnd: () => ends++,
        ));

      try {
        await dio.get<dynamic>('http://example.com/missing');
      } catch (_) {}

      expect(ends, 1);
      final logs = HiveService.instance.apiLogs.values.toList();
      expect(logs.length, 1);
      expect(logs.first.success, isFalse);
      expect(logs.first.statusCode, 404);
    });

    test('沒有 callback 也不會爆', () async {
      final dio = Dio()
        ..httpClientAdapter = _StubAdapter(200, '{}')
        ..interceptors.add(ApiLogInterceptor(HiveService.instance));
      await dio.get<dynamic>('http://x.com/');
      expect(HiveService.instance.apiLogs.length, 1);
    });
  });

  // ============== ApiLog isToday / isWithinDays edge cases ==============

  group('ApiLog 時間判讀', () {
    test('明天的 timestamp 不算今天', () {
      final now = DateTime(2026, 5, 11);
      final tomorrow = ApiLog(
        timestamp: DateTime(2026, 5, 12),
        method: 'GET',
        path: '/x',
        statusCode: 200,
        durationMs: 0,
        success: true,
      );
      expect(tomorrow.isToday(now), isFalse);
    });

    test('isWithinDays(1) 只包含今天', () {
      final now = DateTime(2026, 5, 11, 14);
      final today = ApiLog(
        timestamp: DateTime(2026, 5, 11, 8),
        method: 'GET',
        path: '/x',
        statusCode: 200,
        durationMs: 0,
        success: true,
      );
      expect(today.isWithinDays(1, now), isTrue);
    });
  });
}

/// Dio HttpClientAdapter stub - 直接回固定回應，不打網路
class _StubAdapter implements HttpClientAdapter {
  final int statusCode;
  final String body;
  _StubAdapter(this.statusCode, this.body);

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<dynamic>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
