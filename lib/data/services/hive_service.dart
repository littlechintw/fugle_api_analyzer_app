import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/api_log.dart';
import '../models/candle.dart';
import '../models/holding.dart';
import '../models/price_alert.dart';
import '../models/stock_quote.dart';
import '../models/ticker.dart';
import '../models/watchlist_group.dart';
import '../models/watchlist_item.dart';

/// 集中管理 Hive box 開啟與 TypeAdapter 註冊
class HiveService {
  HiveService._();
  static final HiveService instance = HiveService._();

  // Box 名稱
  static const String candlesBox = 'candles_box';
  static const String quotesBox = 'quotes_box';
  static const String apiLogsBox = 'api_logs_box';
  static const String watchlistBox = 'watchlist_box';
  static const String settingsBox = 'settings_box';
  static const String tickersBox = 'tickers_box';
  static const String priceAlertsBox = 'price_alerts_box';
  static const String watchlistGroupsBox = 'watchlist_groups_box';
  static const String holdingsBox = 'holdings_box';

  bool _initialised = false;

  Future<void> init() async {
    if (_initialised) return;
    await Hive.initFlutter();

    // 註冊 TypeAdapters
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(CandleListAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(StockQuoteAdapter());
    }
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(ApiLogAdapter());
    }
    if (!Hive.isAdapterRegistered(13)) {
      Hive.registerAdapter(WatchlistItemAdapter());
    }
    if (!Hive.isAdapterRegistered(14)) {
      Hive.registerAdapter(TickerAdapter());
    }
    if (!Hive.isAdapterRegistered(15)) {
      Hive.registerAdapter(PriceAlertAdapter());
    }
    if (!Hive.isAdapterRegistered(16)) {
      Hive.registerAdapter(WatchlistGroupAdapter());
    }
    if (!Hive.isAdapterRegistered(17)) {
      Hive.registerAdapter(HoldingAdapter());
    }

    // 開啟所有 box
    await Future.wait([
      Hive.openBox<List>(candlesBox),
      Hive.openBox<StockQuote>(quotesBox),
      Hive.openBox<ApiLog>(apiLogsBox),
      Hive.openBox<WatchlistItem>(watchlistBox),
      Hive.openBox(settingsBox),
      Hive.openBox<Ticker>(tickersBox),
      Hive.openBox<PriceAlert>(priceAlertsBox),
      Hive.openBox<WatchlistGroup>(watchlistGroupsBox),
      Hive.openBox<Holding>(holdingsBox),
    ]);

    _initialised = true;
  }

  Box<List> get candles => Hive.box<List>(candlesBox);
  Box<StockQuote> get quotes => Hive.box<StockQuote>(quotesBox);
  Box<ApiLog> get apiLogs => Hive.box<ApiLog>(apiLogsBox);
  Box<WatchlistItem> get watchlist => Hive.box<WatchlistItem>(watchlistBox);
  Box get settings => Hive.box(settingsBox);
  Box<Ticker> get tickers => Hive.box<Ticker>(tickersBox);
  Box<PriceAlert> get priceAlerts => Hive.box<PriceAlert>(priceAlertsBox);
  Box<WatchlistGroup> get watchlistGroups =>
      Hive.box<WatchlistGroup>(watchlistGroupsBox);
  Box<Holding> get holdings => Hive.box<Holding>(holdingsBox);
}
