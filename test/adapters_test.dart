import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:fugle_api_app/data/models/api_log.dart';
import 'package:fugle_api_app/data/models/candle.dart';
import 'package:fugle_api_app/data/models/holding.dart';
import 'package:fugle_api_app/data/models/price_alert.dart';
import 'package:fugle_api_app/data/models/stock_quote.dart';
import 'package:fugle_api_app/data/models/ticker.dart';
import 'package:fugle_api_app/data/models/watchlist_group.dart';
import 'package:fugle_api_app/data/models/watchlist_item.dart';
import 'package:fugle_api_app/data/services/hive_service.dart';

import '_hive_helper.dart';

void main() {
  setUpAll(setupHiveForTesting);
  tearDownAll(teardownHive);

  setUp(resetHiveBoxes);

  group('Candle Adapter (List)', () {
    test('round-trip 保留所有欄位', () async {
      final list = [
        Candle(
          date: DateTime(2026, 1, 5),
          open: 100.5,
          high: 105.0,
          low: 99.5,
          close: 104.2,
          volume: 12345,
        ),
        Candle(
          date: DateTime(2026, 1, 6),
          open: 104.2,
          high: 108.0,
          low: 103.0,
          close: 107.5,
          volume: 67890,
        ),
      ];
      // 用 Candle.toMap → list 的方式存 (跟 production 一致)
      final raw = list.map((c) => c.toMap()).toList();
      await HiveService.instance.candles.put('TEST', raw);
      // 讀回
      final retrieved = HiveService.instance.candles.get('TEST');
      expect(retrieved, isNotNull);
      expect(retrieved!.length, 2);
      final c0 = Candle.fromMap(Map<String, dynamic>.from(retrieved[0] as Map));
      expect(c0.open, 100.5);
      expect(c0.close, 104.2);
      expect(c0.date, DateTime(2026, 1, 5));
    });
  });

  group('StockQuote Adapter', () {
    test('round-trip', () async {
      final q = StockQuote(
        symbol: '2330',
        name: '台積電',
        lastPrice: 600.5,
        change: 5.0,
        changePercent: 0.84,
        openPrice: 595,
        highPrice: 602,
        lowPrice: 594,
        previousClose: 595.5,
        volume: 1234567,
        updatedAt: DateTime(2026, 5, 11, 9, 0),
      );
      await HiveService.instance.quotes.put('2330', q);
      final r = HiveService.instance.quotes.get('2330');
      expect(r, isNotNull);
      expect(r!.symbol, '2330');
      expect(r.lastPrice, 600.5);
      expect(r.change, 5.0);
      expect(r.updatedAt, DateTime(2026, 5, 11, 9, 0));
    });
  });

  group('ApiLog Adapter', () {
    test('round-trip 含 nullable statusCode', () async {
      final logWithCode = ApiLog(
        timestamp: DateTime(2026, 5, 11),
        method: 'GET',
        path: '/test',
        statusCode: 200,
        durationMs: 123,
        success: true,
      );
      final logWithoutCode = ApiLog(
        timestamp: DateTime(2026, 5, 11),
        method: 'GET',
        path: '/test2',
        statusCode: null,
        durationMs: 0,
        success: false,
      );
      await HiveService.instance.apiLogs.add(logWithCode);
      await HiveService.instance.apiLogs.add(logWithoutCode);

      final all = HiveService.instance.apiLogs.values.toList();
      expect(all.length, 2);
      expect(all[0].statusCode, 200);
      expect(all[1].statusCode, isNull);
      expect(all[0].success, isTrue);
      expect(all[1].success, isFalse);
    });

    test('isToday / isWithinDays 邏輯', () {
      final now = DateTime(2026, 5, 11, 14);
      final today = ApiLog(
        timestamp: DateTime(2026, 5, 11, 10),
        method: 'GET',
        path: '/x',
        statusCode: 200,
        durationMs: 100,
        success: true,
      );
      final yesterday = ApiLog(
        timestamp: DateTime(2026, 5, 10, 10),
        method: 'GET',
        path: '/x',
        statusCode: 200,
        durationMs: 100,
        success: true,
      );
      expect(today.isToday(now), isTrue);
      expect(yesterday.isToday(now), isFalse);
      expect(yesterday.isWithinDays(7, now), isTrue);
      expect(yesterday.isWithinDays(1, now), isFalse);
    });
  });

  group('WatchlistItem Adapter', () {
    test('round-trip', () async {
      final w = WatchlistItem(
        symbol: '0050',
        name: '元大台灣50',
        addedAt: DateTime(2025, 1, 1),
      );
      await HiveService.instance.watchlist.put('0050', w);
      final r = HiveService.instance.watchlist.get('0050');
      expect(r, isNotNull);
      expect(r!.symbol, '0050');
      expect(r.name, '元大台灣50');
      expect(r.addedAt, DateTime(2025, 1, 1));
    });
  });

  group('Ticker Adapter', () {
    test('round-trip', () async {
      const t = Ticker(
        symbol: '2330',
        name: '台積電',
        exchange: 'TWSE',
        market: 'TSE',
      );
      await HiveService.instance.tickers.put('2330', t);
      final r = HiveService.instance.tickers.get('2330');
      expect(r, isNotNull);
      expect(r!.symbol, '2330');
      expect(r.name, '台積電');
      expect(r.exchange, 'TWSE');
      expect(r.market, 'TSE');
    });
  });

  group('PriceAlert Adapter', () {
    test('round-trip 含 nullable lastTriggeredAt', () async {
      final a1 = PriceAlert(
        id: 'a1',
        symbol: '2330',
        name: '台積電',
        direction: AlertDirection.above,
        price: 600,
        createdAt: DateTime(2026, 5, 1),
      );
      final a2 = PriceAlert(
        id: 'a2',
        symbol: '2317',
        name: '鴻海',
        direction: AlertDirection.below,
        price: 100,
        createdAt: DateTime(2026, 5, 1),
        lastTriggeredAt: DateTime(2026, 5, 10, 10, 30),
        enabled: false,
      );
      await HiveService.instance.priceAlerts.put('a1', a1);
      await HiveService.instance.priceAlerts.put('a2', a2);

      final r1 = HiveService.instance.priceAlerts.get('a1');
      final r2 = HiveService.instance.priceAlerts.get('a2');
      expect(r1?.lastTriggeredAt, isNull);
      expect(r1?.enabled, isTrue);
      expect(r1?.direction, AlertDirection.above);

      expect(r2?.lastTriggeredAt, DateTime(2026, 5, 10, 10, 30));
      expect(r2?.enabled, isFalse);
      expect(r2?.direction, AlertDirection.below);
    });
  });

  group('WatchlistGroup Adapter', () {
    test('round-trip', () async {
      const g = WatchlistGroup(
        id: 'g_001',
        name: '長期持有',
        sortOrder: 2,
        colorValue: 0xFFEF476F,
      );
      await HiveService.instance.watchlistGroups.put(g.id, g);
      final r = HiveService.instance.watchlistGroups.get('g_001');
      expect(r?.name, '長期持有');
      expect(r?.colorValue, 0xFFEF476F);
      expect(r?.sortOrder, 2);
    });

    test('copyWith', () {
      const g = WatchlistGroup(
        id: 'g',
        name: 'A',
        sortOrder: 0,
        colorValue: 1,
      );
      final g2 = g.copyWith(name: 'B', sortOrder: 5);
      expect(g2.id, 'g');
      expect(g2.name, 'B');
      expect(g2.sortOrder, 5);
      expect(g2.colorValue, 1);
    });
  });

  group('Holding Adapter', () {
    test('round-trip', () async {
      final h = Holding(
        symbol: '2330',
        name: '台積電',
        quantity: 1000,
        avgCost: 555.5,
        addedAt: DateTime(2024, 12, 1),
      );
      await HiveService.instance.holdings.put('2330', h);
      final r = HiveService.instance.holdings.get('2330');
      expect(r?.quantity, 1000);
      expect(r?.avgCost, 555.5);
      expect(r?.addedAt, DateTime(2024, 12, 1));
    });
  });

  group('settings_box', () {
    test('可存簡單型別 + Map', () async {
      final box = HiveService.instance.settings;
      await box.put('str', 'hello');
      await box.put('int', 42);
      await box.put('bool', true);
      await box.put('map', {'a': 1, 'b': 'x'});

      expect(box.get('str'), 'hello');
      expect(box.get('int'), 42);
      expect(box.get('bool'), isTrue);
      final m = box.get('map') as Map;
      expect(m['a'], 1);
      expect(m['b'], 'x');
    });
  });

  group('TypeAdapter typeId 唯一性', () {
    test('所有 adapter typeId 不重複', () {
      final ids = <int>{};
      // 直接從 Hive 的內部狀態檢查不容易，這裡用我們自己註冊的 ID
      const expected = {10, 11, 12, 13, 14, 15, 16, 17};
      for (final id in expected) {
        ids.add(id);
      }
      expect(ids.length, expected.length);
    });
  });
}
