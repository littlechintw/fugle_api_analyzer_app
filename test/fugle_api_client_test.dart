import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fugle_api_app/data/services/fugle_api_client.dart';
import 'package:fugle_api_app/data/services/secure_storage_service.dart';

import '_hive_helper.dart';

void main() {
  setUpAll(setupHiveForTesting);
  tearDownAll(teardownHive);
  setUp(resetHiveBoxes);

  late _RecordingAdapter adapter;
  late FugleApiClient client;

  setUp(() {
    adapter = _RecordingAdapter();
    client = FugleApiClient.create(storage: _FakeStorage());
    client.dio.httpClientAdapter = adapter;
  });

  group('FugleApiClient', () {
    test('沒設 Token 會拋 FugleApiException', () async {
      final clientNoToken = FugleApiClient.create(storage: _FakeStorage(token: ''));
      clientNoToken.dio.httpClientAdapter = adapter;
      expect(
        () => clientNoToken.intradayQuote('2330'),
        throwsA(isA<FugleApiException>()),
      );
    });

    test('intradayQuote 解析 data', () async {
      adapter.responseBody = '{"data":{"lastPrice":600}}';
      final r = await client.intradayQuote('2330');
      expect(adapter.lastPath, '/stock/intraday/quote/2330');
      expect(adapter.lastHeaders['X-API-KEY'], 'test-token');
      // intradayQuote 直接回傳 raw map
      expect(r['data']?['lastPrice'], 600);
    });

    test('intradayCandles 套上 timeframe + 解析 list', () async {
      adapter.responseBody =
          '{"data":[{"date":"2026-05-11","open":100,"high":101,"low":99,"close":100.5,"volume":1000}]}';
      final r = await client.intradayCandles('2330', timeframe: 5);
      expect(adapter.lastPath, '/stock/intraday/candles/2330');
      expect(adapter.lastQuery['timeframe'], '5');
      expect(r.length, 1);
      expect(r.first['close'], 100.5);
    });

    test('historicalCandles 傳 from/to/timeframe/adjusted', () async {
      adapter.responseBody = '{"data":[]}';
      await client.historicalCandles(
        '2330',
        from: '2026-01-01',
        to: '2026-05-11',
        timeframe: 'W',
        adjusted: true,
      );
      expect(adapter.lastQuery['from'], '2026-01-01');
      expect(adapter.lastQuery['to'], '2026-05-11');
      expect(adapter.lastQuery['timeframe'], 'W');
      expect(adapter.lastQuery['adjusted'], 'true');
      expect(adapter.lastQuery['sort'], 'asc');
    });

    test('historicalCandles adjusted=false 預設', () async {
      adapter.responseBody = '{"data":[]}';
      await client.historicalCandles(
        '2330',
        from: '2026-01-01',
        to: '2026-05-11',
      );
      expect(adapter.lastQuery['adjusted'], 'false');
      expect(adapter.lastQuery['timeframe'], 'D');
    });

    test('historicalStats', () async {
      adapter.responseBody =
          '{"symbol":"0050","week52High":150,"week52Low":80}';
      final r = await client.historicalStats('0050');
      expect(adapter.lastPath, '/stock/historical/stats/0050');
      expect(r['week52High'], 150);
    });

    test('ticker', () async {
      adapter.responseBody = '{"symbol":"2330","name":"台積電"}';
      final r = await client.ticker('2330');
      expect(adapter.lastPath, '/stock/intraday/ticker/2330');
      expect(r['name'], '台積電');
    });

    test('listTickers 注入 exchange/market 到每筆', () async {
      adapter.responseBody = '''
      {
        "exchange":"TWSE",
        "market":"TSE",
        "data":[
          {"symbol":"0050","name":"元大台灣50"},
          {"symbol":"2330","name":"台積電"}
        ]
      }''';
      final r = await client.listTickers(exchange: 'TWSE');
      expect(adapter.lastQuery['type'], 'EQUITY');
      expect(adapter.lastQuery['exchange'], 'TWSE');
      expect(r.length, 2);
      expect(r.first['exchange'], 'TWSE');
      expect(r.first['market'], 'TSE');
    });

    test('listTickers data 內已有 exchange/market 不覆蓋', () async {
      adapter.responseBody = '''
      {
        "data":[
          {"symbol":"X","name":"X","exchange":"OVERRIDE","market":"M"}
        ]
      }''';
      final r = await client.listTickers(exchange: 'TPEx');
      expect(r.first['exchange'], 'OVERRIDE');
      expect(r.first['market'], 'M');
    });

    test('dividends', () async {
      adapter.responseBody = '{"data":[{"date":"2025-08-26","symbol":"X"}]}';
      final r = await client.dividends(
        from: DateTime(2025, 1, 1),
        to: DateTime(2025, 12, 31),
      );
      expect(adapter.lastPath, '/stock/corporate-actions/dividends');
      expect(adapter.lastQuery['start_date'], '2025-01-01');
      expect(adapter.lastQuery['end_date'], '2025-12-31');
      expect(r.length, 1);
    });

    test('capitalChanges', () async {
      adapter.responseBody = '{"data":[]}';
      await client.capitalChanges(
        from: DateTime(2025, 1, 1),
        to: DateTime(2025, 12, 31),
      );
      expect(
        adapter.lastPath,
        '/stock/corporate-actions/capital-changes',
      );
      expect(adapter.lastQuery['start_date'], '2025-01-01');
    });

    test('intradayTrades 帶 limit/offset/sort', () async {
      adapter.responseBody = '{"data":[]}';
      await client.intradayTrades('2330',
          limit: 50, offset: 10, sort: 'asc');
      expect(adapter.lastQuery['limit'], '50');
      expect(adapter.lastQuery['offset'], '10');
      expect(adapter.lastQuery['sort'], 'asc');
    });

    test('intradayVolumes', () async {
      adapter.responseBody = '{"data":[]}';
      await client.intradayVolumes('2330');
      expect(adapter.lastPath, '/stock/intraday/volumes/2330');
    });

    test('snapshotMovers', () async {
      adapter.responseBody = '{"data":[]}';
      await client.snapshotMovers(
        market: 'TSE',
        direction: 'up',
        change: 'value',
      );
      expect(adapter.lastPath, '/stock/snapshot/movers/TSE');
      expect(adapter.lastQuery['direction'], 'up');
      expect(adapter.lastQuery['change'], 'value');
    });

    test('snapshotActives 預設 trade=value', () async {
      adapter.responseBody = '{"data":[]}';
      await client.snapshotActives(market: 'OTC');
      expect(adapter.lastPath, '/stock/snapshot/actives/OTC');
      expect(adapter.lastQuery['trade'], 'value');
    });
  });
}

/// 假的 SecureStorageService — 直接回傳測試用 token
class _FakeStorage implements SecureStorageService {
  final String? token;
  _FakeStorage({this.token = 'test-token'});

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> writeToken(String t) async {}

  @override
  Future<void> deleteToken() async {}
}

/// Dio HttpClientAdapter stub — 記錄請求並回固定回應
class _RecordingAdapter implements HttpClientAdapter {
  String responseBody = '{}';
  int statusCode = 200;

  String? lastPath;
  Map<String, String> lastQuery = {};
  Map<String, String> lastHeaders = {};

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<dynamic>? cancelFuture,
  ) async {
    lastPath = options.path;
    lastQuery = options.queryParameters
        .map((k, v) => MapEntry(k, v.toString()));
    lastHeaders = options.headers
        .map((k, v) => MapEntry(k, v.toString()));
    return ResponseBody.fromString(
      responseBody,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
