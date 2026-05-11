import 'package:dio/dio.dart';

import 'api_log_interceptor.dart';
import 'hive_service.dart';
import 'secure_storage_service.dart';

/// Fugle Market Data REST API 包裝
/// Docs: https://developer.fugle.tw/docs/data/intro
class FugleApiClient {
  static const String baseUrl = 'https://api.fugle.tw/marketdata/v1.0';

  final Dio _dio;
  final SecureStorageService _storage;

  FugleApiClient._(this._dio, this._storage);

  factory FugleApiClient.create({
    SecureStorageService? storage,
    HiveService? hive,
    void Function()? onRequestStart,
    void Function()? onRequestEnd,
  }) {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Accept': 'application/json'},
    ));
    final hiveSvc = hive ?? HiveService.instance;
    dio.interceptors.add(ApiLogInterceptor(
      hiveSvc,
      onRequestStart: onRequestStart,
      onRequestEnd: onRequestEnd,
    ));
    return FugleApiClient._(dio, storage ?? SecureStorageService.instance);
  }

  Future<Options> _authOptions() async {
    final token = await _storage.readToken();
    if (token == null || token.isEmpty) {
      throw const FugleApiException('尚未設定 Fugle API Token，請至設定頁面填寫');
    }
    return Options(headers: {'X-API-KEY': token});
  }

  /// 盤中即時報價
  Future<Map<String, dynamic>> intradayQuote(String symbol) async {
    final opts = await _authOptions();
    final resp = await _dio.get<Map<String, dynamic>>(
      '/stock/intraday/quote/$symbol',
      options: opts,
    );
    return resp.data ?? const {};
  }

  /// 歷史 K 線（candles）
  ///
  /// [from] / [to] 為 yyyy-MM-dd，[timeframe] 可填 D / W / M / 1 / 5 / 60 ...
  /// [adjusted] = false 預設取「交易所實際成交價」(未還原權值)，與當日新聞、
  /// 五檔報價、即時報價的數字一致。設為 true 才會用「還原權值」歷史價。
  Future<List<Map<String, dynamic>>> historicalCandles(
    String symbol, {
    required String from,
    required String to,
    String timeframe = 'D',
    bool adjusted = false,
  }) async {
    final opts = await _authOptions();
    final resp = await _dio.get<Map<String, dynamic>>(
      '/stock/historical/candles/$symbol',
      queryParameters: {
        'from': from,
        'to': to,
        'timeframe': timeframe,
        'sort': 'asc',
        'adjusted': adjusted ? 'true' : 'false',
      },
      options: opts,
    );
    final data = resp.data ?? const {};
    final list = (data['data'] as List?) ?? const [];
    return list.cast<Map<String, dynamic>>();
  }

  /// 當日 1 分鐘 K 線
  /// timeframe 可填 1, 5, 15, 30, 60
  Future<List<Map<String, dynamic>>> intradayCandles(
    String symbol, {
    int timeframe = 1,
  }) async {
    final opts = await _authOptions();
    final resp = await _dio.get<Map<String, dynamic>>(
      '/stock/intraday/candles/$symbol',
      queryParameters: {'timeframe': timeframe.toString()},
      options: opts,
    );
    final list = (resp.data?['data'] as List?) ?? const [];
    return list.cast<Map<String, dynamic>>();
  }

  /// 逐筆成交明細
  Future<List<Map<String, dynamic>>> intradayTrades(
    String symbol, {
    int limit = 100,
    int offset = 0,
    String sort = 'desc',
  }) async {
    final opts = await _authOptions();
    final resp = await _dio.get<Map<String, dynamic>>(
      '/stock/intraday/trades/$symbol',
      queryParameters: {
        'limit': limit.toString(),
        'offset': offset.toString(),
        'sort': sort,
      },
      options: opts,
    );
    final list = (resp.data?['data'] as List?) ?? const [];
    return list.cast<Map<String, dynamic>>();
  }

  /// 分價量表
  Future<List<Map<String, dynamic>>> intradayVolumes(String symbol) async {
    final opts = await _authOptions();
    final resp = await _dio.get<Map<String, dynamic>>(
      '/stock/intraday/volumes/$symbol',
      options: opts,
    );
    final list = (resp.data?['data'] as List?) ?? const [];
    return list.cast<Map<String, dynamic>>();
  }

  /// 漲跌幅排行 (依市場別、方向)
  /// [market]: TSE 上市 / OTC 上櫃
  /// [direction]: up / down
  /// [change]: percent / value
  Future<List<Map<String, dynamic>>> snapshotMovers({
    required String market,
    required String direction,
    String change = 'percent',
  }) async {
    final opts = await _authOptions();
    final resp = await _dio.get<Map<String, dynamic>>(
      '/stock/snapshot/movers/$market',
      queryParameters: {'direction': direction, 'change': change},
      options: opts,
    );
    final list = (resp.data?['data'] as List?) ?? const [];
    return list.cast<Map<String, dynamic>>();
  }

  /// 成交量/值排行
  /// [trade]: volume / value
  Future<List<Map<String, dynamic>>> snapshotActives({
    required String market,
    String trade = 'value',
  }) async {
    final opts = await _authOptions();
    final resp = await _dio.get<Map<String, dynamic>>(
      '/stock/snapshot/actives/$market',
      queryParameters: {'trade': trade},
      options: opts,
    );
    final list = (resp.data?['data'] as List?) ?? const [];
    return list.cast<Map<String, dynamic>>();
  }

  /// 資本變動 (減資 / ETF 分割 / 面額變更)
  Future<List<Map<String, dynamic>>> capitalChanges({
    required DateTime from,
    required DateTime to,
  }) async {
    final opts = await _authOptions();
    final resp = await _dio.get<Map<String, dynamic>>(
      '/stock/corporate-actions/capital-changes',
      queryParameters: {
        'start_date': _dateStr(from),
        'end_date': _dateStr(to),
      },
      options: opts,
    );
    final list = (resp.data?['data'] as List?) ?? const [];
    return list.cast<Map<String, dynamic>>();
  }

  /// 除權息資料 (依日期區間)
  ///
  /// 開發者方案專屬，基本用戶體驗到 2026/2/12
  Future<List<Map<String, dynamic>>> dividends({
    required DateTime from,
    required DateTime to,
  }) async {
    final opts = await _authOptions();
    final f = _dateStr(from);
    final t = _dateStr(to);
    final resp = await _dio.get<Map<String, dynamic>>(
      '/stock/corporate-actions/dividends',
      queryParameters: {'start_date': f, 'end_date': t},
      options: opts,
    );
    final list = (resp.data?['data'] as List?) ?? const [];
    return list.cast<Map<String, dynamic>>();
  }

  static String _dateStr(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// 近 52 週統計
  Future<Map<String, dynamic>> historicalStats(String symbol) async {
    final opts = await _authOptions();
    final resp = await _dio.get<Map<String, dynamic>>(
      '/stock/historical/stats/$symbol',
      options: opts,
    );
    return resp.data ?? const {};
  }

  /// 個股基本資料（名稱等）
  Future<Map<String, dynamic>> ticker(String symbol) async {
    final opts = await _authOptions();
    final resp = await _dio.get<Map<String, dynamic>>(
      '/stock/intraday/ticker/$symbol',
      options: opts,
    );
    return resp.data ?? const {};
  }

  /// 取得某市場的所有代號清單。
  /// [exchange] = TWSE (上市) 或 TPEx (上櫃)；[type] 預設 EQUITY。
  /// 回傳已將外層 `exchange`/`market` 注入到每筆資料中。
  Future<List<Map<String, dynamic>>> listTickers({
    required String exchange,
    String type = 'EQUITY',
  }) async {
    final opts = await _authOptions();
    final resp = await _dio.get<Map<String, dynamic>>(
      '/stock/intraday/tickers',
      queryParameters: {'type': type, 'exchange': exchange},
      options: opts,
    );
    final data = resp.data ?? const {};
    final outerExchange = (data['exchange'] ?? exchange) as String;
    final outerMarket = (data['market'] ?? '') as String;
    final list = (data['data'] as List?) ?? const [];
    return list
        .cast<Map<String, dynamic>>()
        .map((m) => {
              ...m,
              'exchange': m['exchange'] ?? outerExchange,
              'market': m['market'] ?? outerMarket,
            })
        .toList();
  }
}

class FugleApiException implements Exception {
  final String message;
  const FugleApiException(this.message);
  @override
  String toString() => message;
}
