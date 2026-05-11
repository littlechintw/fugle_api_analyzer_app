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

  /// 歷史日 K 線（candles）
  ///
  /// [from] / [to] 為 yyyy-MM-dd
  Future<List<Map<String, dynamic>>> historicalCandles(
    String symbol, {
    required String from,
    required String to,
  }) async {
    final opts = await _authOptions();
    final resp = await _dio.get<Map<String, dynamic>>(
      '/stock/historical/candles/$symbol',
      queryParameters: {'from': from, 'to': to},
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
