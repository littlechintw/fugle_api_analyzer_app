import 'package:intl/intl.dart';

import '../models/candle.dart';
import '../models/stock_quote.dart';
import 'fugle_api_client.dart';
import 'hive_service.dart';

/// 股票資料 Repository
///
/// 負責「本地快取優先 → 過期才打 API」的決策邏輯，降低 API 呼叫量。
class StockRepository {
  final FugleApiClient _api;
  final HiveService _hive;

  StockRepository(this._api, this._hive);

  static final _dateFmt = DateFormat('yyyy-MM-dd');

  // ============== Quote (盤中即時) ==============

  /// 預設 60 秒內視為新鮮快取
  static const Duration quoteFreshness = Duration(seconds: 60);

  Future<StockQuote> getQuote(String symbol, {bool forceRefresh = false}) async {
    final cached = _hive.quotes.get(symbol);
    final now = DateTime.now();
    if (!forceRefresh &&
        cached != null &&
        now.difference(cached.updatedAt) < quoteFreshness) {
      return cached;
    }
    final json = await _api.intradayQuote(symbol);
    // Fugle 回應通常包在 { data: { ... } } 內，視情況拆解
    final payload = (json['data'] as Map<String, dynamic>?) ?? json;
    final quote = StockQuote.fromFugleQuote({
      'symbol': symbol,
      ...payload,
    });
    await _hive.quotes.put(symbol, quote);
    return quote;
  }

  StockQuote? cachedQuote(String symbol) => _hive.quotes.get(symbol);

  // ============== Candles (歷史日 K) ==============

  /// 取得近 [days] 個 K 棒；[timeframe] 預設 D（日 K），可改 W、M
  ///
  /// 快取策略：日 K 走 Hive 快取 (key = symbol)；週 / 月 K 因頻率低，
  /// 每次直接 fetch 不快取（也避免 key 跟日 K 衝突）。
  Future<List<Candle>> getDailyCandles(
    String symbol, {
    int days = 180,
    String timeframe = 'D',
    bool forceRefresh = false,
  }) async {
    final isDaily = timeframe == 'D';
    if (isDaily) {
      final cached = _readCachedCandles(symbol);
      final today = _today();
      final hasFreshCache = cached.isNotEmpty &&
          _isSameDay(cached.last.date, today) &&
          cached.length >= days * 0.6;
      if (!forceRefresh && hasFreshCache) {
        return cached.length > days
            ? cached.sublist(cached.length - days)
            : cached;
      }
    }

    final to = _today();
    final from = to.subtract(
      Duration(days: _windowDays(days: days, timeframe: timeframe)),
    );
    final raw = await _api.historicalCandles(
      symbol,
      from: _dateFmt.format(from),
      to: _dateFmt.format(to),
      timeframe: timeframe,
    );
    final fresh = raw.map(Candle.fromFugleHistorical).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (isDaily) {
      await _hive.candles.put(symbol, fresh.map((c) => c.toMap()).toList());
    }
    return fresh.length > days
        ? fresh.sublist(fresh.length - days)
        : fresh;
  }

  /// 不同週期需要往回拉的「日曆天數」估算
  static int _windowDays({required int days, required String timeframe}) {
    switch (timeframe) {
      case 'W':
        return days * 7 + 14;
      case 'M':
        return days * 31 + 30;
      case 'D':
      default:
        return (days * 1.6).round() + 10;
    }
  }

  List<Candle> _readCachedCandles(String symbol) {
    final raw = _hive.candles.get(symbol);
    if (raw == null) return const [];
    return raw
        .cast<Map>()
        .map((m) => Candle.fromMap(Map<String, dynamic>.from(m)))
        .toList();
  }

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
