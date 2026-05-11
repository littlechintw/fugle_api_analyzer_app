import 'package:flutter_test/flutter_test.dart';

import 'package:fugle_api_app/data/services/fugle_api_client.dart';
import 'package:fugle_api_app/data/services/hive_service.dart';
import 'package:fugle_api_app/data/services/stock_repository.dart';

import '_hive_helper.dart';

/// 用最簡單的 stub 取代 FugleApiClient，避免真打網路
class _StubFugleApiClient implements FugleApiClient {
  int intradayQuoteCalls = 0;
  int historicalCallsCount = 0;
  String? lastTimeframe;
  bool? lastAdjusted;
  List<Map<String, dynamic>> Function()? candleSupplier;
  Map<String, dynamic> Function()? quoteSupplier;

  @override
  Future<Map<String, dynamic>> intradayQuote(String symbol) async {
    intradayQuoteCalls++;
    return (quoteSupplier ??
            () => {
                  'symbol': symbol,
                  'lastPrice': 100.0,
                  'previousClose': 99.0,
                })
        .call();
  }

  @override
  Future<List<Map<String, dynamic>>> historicalCandles(
    String symbol, {
    required String from,
    required String to,
    String timeframe = 'D',
    bool adjusted = false,
  }) async {
    historicalCallsCount++;
    lastTimeframe = timeframe;
    lastAdjusted = adjusted;
    return (candleSupplier ??
            () => [
                  {
                    'date': '2026-05-08',
                    'open': 100,
                    'high': 101,
                    'low': 99,
                    'close': 100.5,
                    'volume': 1000,
                  },
                  {
                    'date': '2026-05-11', // 模擬「今日」
                    'open': 100.5,
                    'high': 102,
                    'low': 100,
                    'close': 101.5,
                    'volume': 2000,
                  },
                ])
        .call();
  }

  // 其餘方法不會在這個測試中呼叫
  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  setUpAll(setupHiveForTesting);
  tearDownAll(teardownHive);

  setUp(resetHiveBoxes);

  group('StockRepository.getDailyCandles', () {
    test('第一次呼叫會打 API，第二次走快取', () async {
      final api = _StubFugleApiClient();
      final today = DateTime.now();
      // 產生 30 根日 K，最後一根為今天 → 滿足 hasFreshCache 條件
      api.candleSupplier = () {
        final result = <Map<String, dynamic>>[];
        for (var i = 29; i >= 0; i--) {
          final d = today.subtract(Duration(days: i));
          result.add({
            'date':
                '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
            'open': 100,
            'high': 101,
            'low': 99,
            'close': 100.0 + i,
            'volume': 1000,
          });
        }
        return result;
      };

      final repo = StockRepository(api, HiveService.instance);

      final r1 = await repo.getDailyCandles('TEST', days: 30);
      expect(r1.length, greaterThan(0));
      expect(api.historicalCallsCount, 1);

      final r2 = await repo.getDailyCandles('TEST', days: 30);
      expect(r2.length, r1.length);
      // 第二次應該命中快取
      expect(api.historicalCallsCount, 1);
    });

    test('forceRefresh = true 強制重打 API', () async {
      final api = _StubFugleApiClient();
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      api.candleSupplier = () => [
            {
              'date': todayStr,
              'open': 100,
              'high': 101,
              'low': 99,
              'close': 100.5,
              'volume': 1000,
            },
          ];

      final repo = StockRepository(api, HiveService.instance);
      await repo.getDailyCandles('TEST', days: 30);
      await repo.getDailyCandles('TEST', days: 30, forceRefresh: true);
      expect(api.historicalCallsCount, 2);
    });

    test('週 K / 月 K 不走快取', () async {
      final api = _StubFugleApiClient();
      api.candleSupplier = () => [
            {
              'date': '2026-05-08',
              'open': 100,
              'high': 101,
              'low': 99,
              'close': 100.5,
              'volume': 1000,
            },
          ];
      final repo = StockRepository(api, HiveService.instance);
      await repo.getDailyCandles('TEST', timeframe: 'W');
      await repo.getDailyCandles('TEST', timeframe: 'W');
      // 每次都打
      expect(api.historicalCallsCount, 2);
    });

    test('採用 adjusted=false', () async {
      final api = _StubFugleApiClient();
      api.candleSupplier = () => [
            {
              'date': '2026-05-08',
              'open': 100,
              'high': 101,
              'low': 99,
              'close': 100.5,
              'volume': 1000,
            },
          ];
      final repo = StockRepository(api, HiveService.instance);
      await repo.getDailyCandles('TEST');
      expect(api.lastAdjusted, isFalse);
    });
  });

  group('StockRepository.getQuote', () {
    test('60 秒內走快取', () async {
      final api = _StubFugleApiClient();
      final repo = StockRepository(api, HiveService.instance);

      await repo.getQuote('TEST');
      expect(api.intradayQuoteCalls, 1);
      await repo.getQuote('TEST');
      expect(api.intradayQuoteCalls, 1); // 60s 內命中
    });

    test('forceRefresh 強制重打', () async {
      final api = _StubFugleApiClient();
      final repo = StockRepository(api, HiveService.instance);

      await repo.getQuote('TEST');
      await repo.getQuote('TEST', forceRefresh: true);
      expect(api.intradayQuoteCalls, 2);
    });

    test('cachedQuote 在 putQuote 後取得', () async {
      final api = _StubFugleApiClient();
      final repo = StockRepository(api, HiveService.instance);

      expect(repo.cachedQuote('TEST'), isNull);
      await repo.getQuote('TEST');
      expect(repo.cachedQuote('TEST'), isNotNull);
      expect(repo.cachedQuote('TEST')!.lastPrice, 100.0);
    });
  });
}
