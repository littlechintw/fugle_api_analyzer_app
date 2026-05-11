import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../indicators/indicators.dart';
import '../models/api_log.dart';
import '../models/candle.dart';
import '../models/stock_quote.dart';
import '../models/watchlist_item.dart';
import '../models/dividend.dart';
import '../models/fundamental.dart';
import '../models/historical_stats.dart';
import '../models/institutional_flow.dart';
import '../models/intraday_candle.dart';
import '../models/market_mover.dart';
import '../models/order_book.dart';
import '../models/ticker.dart';
import '../services/fugle_api_client.dart';
import '../services/twse_api_client.dart';
import '../services/hive_service.dart';
import '../services/secure_storage_service.dart';
import '../services/stock_repository.dart';
import '../services/ticker_catalog_service.dart';
import '../services/twse_fundamental_client.dart';
import 'chart_options_provider.dart';
import 'network_activity_provider.dart';
import 'price_alert_provider.dart';
import 'trade_color_provider.dart';
import 'watchlist_group_provider.dart';
import 'watchlist_sort_provider.dart';

export 'chart_options_provider.dart'
    show
        chartOptionsProvider,
        ChartOptions,
        ChartTimeframe,
        ChartRange,
        ChartTimeframeMeta,
        ChartRangeMeta;
export 'network_activity_provider.dart' show networkActivityProvider;
export 'price_alert_provider.dart' show priceAlertsProvider;
export 'trade_color_provider.dart' show tradeColorModeProvider;
export 'watchlist_group_provider.dart'
    show watchlistGroupsProvider, selectedGroupProvider;
export 'watchlist_sort_provider.dart'
    show watchlistSortProvider, WatchlistSort, WatchlistSortLabel;

// ============== 基礎服務 ==============

final hiveServiceProvider = Provider<HiveService>((_) => HiveService.instance);

final secureStorageProvider =
    Provider<SecureStorageService>((_) => SecureStorageService.instance);

final fugleApiClientProvider = Provider<FugleApiClient>((ref) {
  final activity = ref.read(networkActivityProvider.notifier);
  return FugleApiClient.create(
    storage: ref.watch(secureStorageProvider),
    hive: ref.watch(hiveServiceProvider),
    onRequestStart: activity.increment,
    onRequestEnd: activity.decrement,
  );
});

final stockRepositoryProvider = Provider<StockRepository>((ref) {
  return StockRepository(
    ref.watch(fugleApiClientProvider),
    ref.watch(hiveServiceProvider),
  );
});

final tickerCatalogServiceProvider = Provider<TickerCatalogService>((ref) {
  return TickerCatalogService(
    ref.watch(fugleApiClientProvider),
    ref.watch(hiveServiceProvider),
  );
});

/// 自動載入代號目錄，UI 端 `ref.watch` 即會觸發第一次拉取
final tickerCatalogProvider = FutureProvider<List<Ticker>>((ref) async {
  return ref.watch(tickerCatalogServiceProvider).load();
});

// ============== API Token ==============

enum TokenValidity { unchecked, verifying, valid, invalid }

class ApiTokenState {
  final String? token;
  final TokenValidity validity;
  final String? errorMessage;
  const ApiTokenState({
    this.token,
    this.validity = TokenValidity.unchecked,
    this.errorMessage,
  });

  bool get hasToken => token != null && token!.isNotEmpty;

  ApiTokenState copyWith({
    String? token,
    TokenValidity? validity,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ApiTokenState(
      token: token ?? this.token,
      validity: validity ?? this.validity,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ApiTokenNotifier extends AsyncNotifier<ApiTokenState> {
  @override
  Future<ApiTokenState> build() async {
    final t = await ref.read(secureStorageProvider).readToken();
    return ApiTokenState(token: t);
  }

  /// 儲存 + 立即驗證
  Future<void> save(String raw) async {
    final token = raw.trim();
    if (token.isEmpty) {
      await ref.read(secureStorageProvider).deleteToken();
      state = const AsyncValue.data(ApiTokenState());
      return;
    }
    await ref.read(secureStorageProvider).writeToken(token);
    state = AsyncValue.data(
      ApiTokenState(token: token, validity: TokenValidity.verifying),
    );
    // 真正驗證
    final api = ref.read(fugleApiClientProvider);
    try {
      // 用一個輕量端點測試 — 查 0050 ticker
      await api.ticker('0050');
      state = AsyncValue.data(
        ApiTokenState(token: token, validity: TokenValidity.valid),
      );
    } catch (e) {
      state = AsyncValue.data(
        ApiTokenState(
          token: token,
          validity: TokenValidity.invalid,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> clear() async {
    await ref.read(secureStorageProvider).deleteToken();
    state = const AsyncValue.data(ApiTokenState());
  }
}

final apiTokenProvider =
    AsyncNotifierProvider<ApiTokenNotifier, ApiTokenState>(
        ApiTokenNotifier.new);

// ============== API 統計 ==============

class ApiStats {
  final int today;
  final int last7Days;
  final int total;
  final int success;
  final int failure;
  final int todaySuccess;
  final int todayFailure;
  final List<ApiLog> recent;
  const ApiStats({
    required this.today,
    required this.last7Days,
    required this.total,
    required this.success,
    required this.failure,
    required this.todaySuccess,
    required this.todayFailure,
    required this.recent,
  });

  double get successRate => total == 0 ? 0 : success / total;
}

final apiStatsProvider = StreamProvider<ApiStats>((ref) async* {
  final box = ref.watch(hiveServiceProvider).apiLogs;
  ApiStats compute() {
    final now = DateTime.now();
    final logs = box.values.toList();
    var success = 0;
    var failure = 0;
    var todaySuccess = 0;
    var todayFailure = 0;
    var today = 0;
    var last7 = 0;
    for (final l in logs) {
      if (l.success) {
        success++;
      } else {
        failure++;
      }
      if (l.isToday(now)) {
        today++;
        if (l.success) {
          todaySuccess++;
        } else {
          todayFailure++;
        }
      }
      if (l.isWithinDays(7, now)) last7++;
    }
    final recent = logs.reversed.take(50).toList();
    return ApiStats(
      today: today,
      last7Days: last7,
      total: logs.length,
      success: success,
      failure: failure,
      todaySuccess: todaySuccess,
      todayFailure: todayFailure,
      recent: recent,
    );
  }

  yield compute();
  await for (final _ in box.watch()) {
    yield compute();
  }
});

// ============== 自選股 ==============

class WatchlistNotifier extends Notifier<List<WatchlistItem>> {
  @override
  List<WatchlistItem> build() {
    final box = ref.read(hiveServiceProvider).watchlist;
    _seedIfEmpty(box);
    return box.values.toList();
  }

  void _seedIfEmpty(Box<WatchlistItem> box) {
    if (box.isEmpty) {
      final seed = <Map<String, String>>[
        {'symbol': '2330', 'name': '台積電'},
        {'symbol': '2317', 'name': '鴻海'},
        {'symbol': '2454', 'name': '聯發科'},
        {'symbol': '0050', 'name': '元大台灣50'},
      ];
      for (final s in seed) {
        box.put(
          s['symbol'],
          WatchlistItem(
            symbol: s['symbol']!,
            name: s['name']!,
            addedAt: DateTime.now(),
          ),
        );
      }
    }
  }

  void add(String symbol, String name) {
    final box = ref.read(hiveServiceProvider).watchlist;
    box.put(
      symbol,
      WatchlistItem(
        symbol: symbol,
        name: name,
        addedAt: DateTime.now(),
      ),
    );
    state = box.values.toList();
  }

  void remove(String symbol) {
    final box = ref.read(hiveServiceProvider).watchlist;
    box.delete(symbol);
    state = box.values.toList();
  }
}

final watchlistProvider =
    NotifierProvider<WatchlistNotifier, List<WatchlistItem>>(
        WatchlistNotifier.new);

// ============== 個股資料 (家族 provider) ==============

/// 用 family 以 symbol 為 key
final quoteProvider =
    FutureProvider.family<StockQuote, String>((ref, symbol) async {
  return ref.watch(stockRepositoryProvider).getQuote(symbol);
});

final candlesProvider =
    FutureProvider.family<List<Candle>, String>((ref, symbol) async {
  final opts = ref.watch(chartOptionsProvider);
  return ref.watch(stockRepositoryProvider).getDailyCandles(
        symbol,
        timeframe: opts.timeframe.apiCode,
        days: opts.range.displayBarsFor(opts.timeframe),
      );
});

/// 五檔買賣盤 — 不快取，每次直接打 intraday/quote
final orderBookProvider =
    FutureProvider.family<OrderBookSnapshot, String>((ref, symbol) async {
  final api = ref.watch(fugleApiClientProvider);
  final raw = await api.intradayQuote(symbol);
  return OrderBookSnapshot.fromFugleQuote(symbol, raw);
});

/// 除權息資料 — 整批抓近 5 年再依股票篩
/// 同一 session 共用快取 (Riverpod 自動快取)，App 重啟才會再打
final _dividendsBundleProvider =
    FutureProvider<List<Dividend>>((ref) async {
  final api = ref.watch(fugleApiClientProvider);
  final now = DateTime.now();
  final from = DateTime(now.year - 5, 1, 1);
  final to = DateTime(now.year + 1, 1, 1); // 含未來預告
  final raw = await api.dividends(from: from, to: to);
  return raw.map(Dividend.fromFugle).toList()
    ..sort((a, b) => b.date.compareTo(a.date));
});

final dividendsProvider =
    FutureProvider.family<List<Dividend>, String>((ref, symbol) async {
  final all = await ref.watch(_dividendsBundleProvider.future);
  return all.where((d) => d.symbol == symbol).toList();
});

/// 52 週統計 — 一日內快取 (家族 in-memory)
final historicalStatsProvider =
    FutureProvider.family<HistoricalStats, String>((ref, symbol) async {
  final api = ref.watch(fugleApiClientProvider);
  final raw = await api.historicalStats(symbol);
  return HistoricalStats.fromFugle({'symbol': symbol, ...raw});
});

/// 加權指數 K 線 (固定 symbol = IR0001)，跟個股 timeframe / range 同步
final indexCandlesProvider = FutureProvider<List<Candle>>((ref) async {
  final opts = ref.watch(chartOptionsProvider);
  return ref.watch(stockRepositoryProvider).getDailyCandles(
        'IR0001',
        timeframe: opts.timeframe.apiCode,
        days: opts.range.displayBarsFor(opts.timeframe),
      );
});

/// 是否在 K 線上疊加大盤對比
class CompareIndexNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void toggle() => state = !state;
}

final compareIndexProvider =
    NotifierProvider<CompareIndexNotifier, bool>(CompareIndexNotifier.new);

/// 當日 1 分鐘 K - 不快取，每次重新打 (盤中會持續更新)
final intradayCandlesProvider =
    FutureProvider.family<List<IntradayCandle>, String>((ref, symbol) async {
  final api = ref.watch(fugleApiClientProvider);
  final raw = await api.intradayCandles(symbol);
  return raw.map(IntradayCandle.fromFugle).toList()
    ..sort((a, b) => a.time.compareTo(b.time));
});

// ============== 市場熱度排行 ==============

enum MarketBoard { tse, otc }
enum MoversKind { gainers, losers, volume, value }

extension MarketBoardCode on MarketBoard {
  String get code => switch (this) {
        MarketBoard.tse => 'TSE',
        MarketBoard.otc => 'OTC',
      };
  String get label => switch (this) {
        MarketBoard.tse => '上市',
        MarketBoard.otc => '上櫃',
      };
}

extension MoversKindMeta on MoversKind {
  String get label => switch (this) {
        MoversKind.gainers => '漲幅',
        MoversKind.losers => '跌幅',
        MoversKind.volume => '成交量',
        MoversKind.value => '成交值',
      };
}

final marketMoversProvider = FutureProvider.family<List<MarketMover>,
    ({MarketBoard board, MoversKind kind})>((ref, args) async {
  final api = ref.watch(fugleApiClientProvider);
  List<Map<String, dynamic>> raw;
  switch (args.kind) {
    case MoversKind.gainers:
      raw = await api.snapshotMovers(
          market: args.board.code, direction: 'up', change: 'percent');
      break;
    case MoversKind.losers:
      raw = await api.snapshotMovers(
          market: args.board.code, direction: 'down', change: 'percent');
      break;
    case MoversKind.volume:
      raw = await api.snapshotActives(
          market: args.board.code, trade: 'volume');
      break;
    case MoversKind.value:
      raw = await api.snapshotActives(
          market: args.board.code, trade: 'value');
      break;
  }
  return raw.map(MarketMover.fromFugle).toList();
});

// ============== 基本面 (TWSE OpenAPI) ==============

final twseFundamentalClientProvider =
    Provider<TwseFundamentalClient>((ref) {
  return TwseFundamentalClient.create(
    hive: ref.watch(hiveServiceProvider),
  );
});

final fundamentalProvider =
    FutureProvider.family<FundamentalSnapshot?, String>((ref, symbol) async {
  return ref.watch(twseFundamentalClientProvider).bySymbol(symbol);
});

// ============== 三大法人 (TWSE) ==============

final twseApiClientProvider = Provider<TwseApiClient>((ref) {
  return TwseApiClient.create(hive: ref.watch(hiveServiceProvider));
});

/// 漸進式 stream — 吐 InstitutionalSnapshot，含 loaded/total/isComplete
final institutionalFlowProvider =
    StreamProvider.family<InstitutionalSnapshot, String>(
        (ref, symbol) {
  final api = ref.watch(twseApiClientProvider);
  return api.recentFlowsSnapshotStream(symbol, days: 5);
});

final diagnosisProvider =
    Provider.family<List<DiagnosisTag>, String>((ref, symbol) {
  final async = ref.watch(candlesProvider(symbol));
  return async.maybeWhen(
    data: (c) => Diagnoser.diagnose(c),
    orElse: () => const [],
  );
});
