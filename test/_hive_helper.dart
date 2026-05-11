import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:fugle_api_app/data/models/api_log.dart';
import 'package:fugle_api_app/data/models/holding.dart';
import 'package:fugle_api_app/data/models/price_alert.dart';
import 'package:fugle_api_app/data/models/stock_quote.dart';
import 'package:fugle_api_app/data/models/ticker.dart';
import 'package:fugle_api_app/data/models/watchlist_group.dart';
import 'package:fugle_api_app/data/models/watchlist_item.dart';
import 'package:fugle_api_app/data/services/hive_service.dart';

/// 測試用的 Hive 設定：每組測試開一個獨立 temp dir。
///
/// 用法：
/// ```dart
/// setUpAll(setupHiveForTesting);
/// tearDownAll(teardownHive);
/// ```
late Directory _tempDir;

Future<void> setupHiveForTesting() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  _tempDir = await Directory.systemTemp.createTemp('hive_test_');
  Hive.init(_tempDir.path);

  // 註冊所有 adapters
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

  // 開啟與 HiveService 相同的 box，這樣可以用 HiveService.instance
  // (但要先確保未初始化，否則跳過)
  await Future.wait([
    Hive.openBox<List>(HiveService.candlesBox),
    Hive.openBox<StockQuote>(HiveService.quotesBox),
    Hive.openBox<ApiLog>(HiveService.apiLogsBox),
    Hive.openBox<WatchlistItem>(HiveService.watchlistBox),
    Hive.openBox(HiveService.settingsBox),
    Hive.openBox<Ticker>(HiveService.tickersBox),
    Hive.openBox<PriceAlert>(HiveService.priceAlertsBox),
    Hive.openBox<WatchlistGroup>(HiveService.watchlistGroupsBox),
    Hive.openBox<Holding>(HiveService.holdingsBox),
  ]);
}

/// 每個測試之間清空所有 box (但不關閉)
Future<void> resetHiveBoxes() async {
  await HiveService.instance.candles.clear();
  await HiveService.instance.quotes.clear();
  await HiveService.instance.apiLogs.clear();
  await HiveService.instance.watchlist.clear();
  await HiveService.instance.settings.clear();
  await HiveService.instance.tickers.clear();
  await HiveService.instance.priceAlerts.clear();
  await HiveService.instance.watchlistGroups.clear();
  await HiveService.instance.holdings.clear();
}

Future<void> teardownHive() async {
  await Hive.close();
  if (_tempDir.existsSync()) {
    _tempDir.deleteSync(recursive: true);
  }
}
