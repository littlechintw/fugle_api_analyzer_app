import 'package:dio/dio.dart';

import '../models/fundamental.dart';
import 'hive_service.dart';

/// TWSE OpenAPI 基本面資料
///
/// 端點 https://openapi.twse.com.tw/v1/exchangeReport/BWIBBU_d
/// 回傳當日 (T-1) 全市場個股的本益比、殖利率、股價淨值比
///
/// 設計：類似 TwseApiClient，整批抓回來 Hive 快取一天，
/// 多檔股票共用同一份快取
class TwseFundamentalClient {
  static const String _url =
      'https://openapi.twse.com.tw/v1/exchangeReport/BWIBBU_d';
  static const String _cacheKey = 'fundamental_bwibbu';
  static const String _cacheDateKey = 'fundamental_bwibbu_date';

  final Dio _dio;
  final HiveService _hive;

  TwseFundamentalClient._(this._dio, this._hive);

  factory TwseFundamentalClient.create({HiveService? hive}) {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 12),
      headers: {'Accept': 'application/json'},
    ));
    return TwseFundamentalClient._(dio, hive ?? HiveService.instance);
  }

  /// 取得個股基本面，會自動使用整日快取
  Future<FundamentalSnapshot?> bySymbol(String symbol) async {
    final all = await _loadAll();
    final row = all[symbol];
    if (row == null) return null;
    return FundamentalSnapshot.fromTwse(symbol, Map<String, dynamic>.from(row));
  }

  Future<Map<String, Map>> _loadAll() async {
    // 檢查快取是否為今日
    final today = _todayStr();
    final cachedDate = _hive.settings.get(_cacheDateKey) as String?;
    if (cachedDate == today) {
      final raw = _hive.settings.get(_cacheKey);
      if (raw is Map) {
        return Map<String, Map>.from(
          raw.map((k, v) => MapEntry(k.toString(), v as Map)),
        );
      }
    }

    // 抓 API
    try {
      final resp = await _dio.get<List>(_url);
      final list = resp.data ?? const [];
      final byCode = <String, Map>{};
      for (final r in list) {
        if (r is! Map) continue;
        final code = (r['Code'] ?? r['證券代號'] ?? '').toString().trim();
        if (code.isEmpty) continue;
        byCode[code] = {
          '本益比': r['PEratio'] ?? r['本益比'],
          '股價淨值比': r['PBratio'] ?? r['股價淨值比'],
          '殖利率(%)': r['DividendYield'] ?? r['殖利率(%)'],
          '股利年度': r['FinancialReportYear'] ?? r['股利年度'],
        };
      }
      await _hive.settings.put(_cacheKey, byCode);
      await _hive.settings.put(_cacheDateKey, today);
      return byCode;
    } catch (_) {
      return const {};
    }
  }

  String _todayStr() {
    final n = DateTime.now();
    return '${n.year}${n.month.toString().padLeft(2, '0')}'
        '${n.day.toString().padLeft(2, '0')}';
  }
}
