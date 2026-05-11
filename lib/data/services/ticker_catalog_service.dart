import '../models/ticker.dart';
import 'fugle_api_client.dart';
import 'hive_service.dart';

/// 全市場股票代號目錄。
///
/// 第一次需要時拉 TWSE + TPEx 兩個交易所的清單，存進 Hive，
/// 之後 24 小時內不再打 API。
class TickerCatalogService {
  final FugleApiClient _api;
  final HiveService _hive;

  TickerCatalogService(this._api, this._hive);

  static const _ttl = Duration(hours: 24);
  static const _fetchedAtKey = 'tickers_fetched_at';

  /// 是否需要重新抓取
  bool get isStale {
    final settings = _hive.settings;
    final stamp = settings.get(_fetchedAtKey) as int?;
    if (stamp == null) return true;
    final age =
        DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(stamp));
    return age > _ttl;
  }

  /// 載入清單；若本地過期則先打 API 再回傳。
  Future<List<Ticker>> load({bool forceRefresh = false}) async {
    if (!forceRefresh && !isStale && _hive.tickers.isNotEmpty) {
      return _sorted(_hive.tickers.values.toList());
    }
    final merged = <String, Ticker>{};
    for (final ex in const ['TWSE', 'TPEx']) {
      try {
        final raw = await _api.listTickers(exchange: ex);
        for (final m in raw) {
          final t = Ticker.fromFugle(m);
          if (t.symbol.isEmpty) continue;
          merged[t.symbol] = t;
        }
      } catch (_) {
        // 單一交易所失敗仍嘗試另一個
      }
    }
    if (merged.isNotEmpty) {
      await _hive.tickers.clear();
      await _hive.tickers.putAll(merged);
      await _hive.settings
          .put(_fetchedAtKey, DateTime.now().millisecondsSinceEpoch);
    }
    return _sorted(_hive.tickers.values.toList());
  }

  /// 用代號或名稱搜尋（不分大小寫，部分比對）
  List<Ticker> search(String query, {int limit = 50}) {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final all = _hive.tickers.values;
    final out = <Ticker>[];
    final lower = q.toLowerCase();
    for (final t in all) {
      if (t.symbol.startsWith(q) ||
          t.name.contains(q) ||
          t.symbol.toLowerCase().contains(lower) ||
          t.name.toLowerCase().contains(lower)) {
        out.add(t);
        if (out.length >= limit) break;
      }
    }
    // 代號完全相等優先
    out.sort((a, b) {
      final ea = a.symbol == q ? 0 : 1;
      final eb = b.symbol == q ? 0 : 1;
      if (ea != eb) return ea - eb;
      return a.symbol.compareTo(b.symbol);
    });
    return out;
  }

  Ticker? findBySymbol(String symbol) => _hive.tickers.get(symbol);

  List<Ticker> _sorted(List<Ticker> xs) {
    xs.sort((a, b) => a.symbol.compareTo(b.symbol));
    return xs;
  }

  DateTime? lastFetchedAt() {
    final ts = _hive.settings.get(_fetchedAtKey) as int?;
    return ts == null ? null : DateTime.fromMillisecondsSinceEpoch(ts);
  }
}
