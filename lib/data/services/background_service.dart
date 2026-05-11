import 'package:dio/dio.dart';
import 'package:workmanager/workmanager.dart';

import '../models/price_alert.dart';
import '../providers/background_refresh_provider.dart';
import 'hive_service.dart';
import 'notification_service.dart';
import 'secure_storage_service.dart';

/// 背景刷新任務名稱
const String backgroundRefreshTaskName = 'price_alert_check';

/// 由 workmanager 在背景 isolate 呼叫的 entry point
///
/// 注意：背景 isolate 沒有共享 Hive instance 與 Riverpod state，
/// 必須重新初始化所需資源。
@pragma('vm:entry-point')
void backgroundCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName != backgroundRefreshTaskName) return true;
    try {
      // 1. 初始化 Hive (背景 isolate 需要)
      await HiveService.instance.init();
      await NotificationService.instance.init();

      // 2. 讀取 API Token
      final token = await SecureStorageService.instance.readToken();
      if (token == null || token.isEmpty) return true;

      // 3. 取得自選股
      final watchlist = HiveService.instance.watchlist.values.toList();
      if (watchlist.isEmpty) return true;

      // 4. 讀取所有警示
      final alerts = HiveService.instance.priceAlerts.values.toList();
      if (alerts.isEmpty) return true;

      // 5. 對每檔有警示的股票打 quote API
      final dio = Dio(BaseOptions(
        baseUrl: 'https://api.fugle.tw/marketdata/v1.0',
        headers: {'X-API-KEY': token},
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 10),
      ));
      final symbols = alerts
          .where((a) => a.enabled)
          .map((a) => a.symbol)
          .toSet()
          .toList();
      final priceBySymbol = <String, double>{};
      for (final s in symbols) {
        try {
          final r = await dio.get<Map<String, dynamic>>(
            '/stock/intraday/quote/$s',
          );
          final data = (r.data?['data'] as Map?) ?? r.data ?? const {};
          final p = (data['lastPrice'] ?? data['closePrice']);
          if (p is num) priceBySymbol[s] = p.toDouble();
        } catch (_) {
          // skip
        }
      }

      // 6. 檢查觸發
      final hits = <({PriceAlert alert, double currentPrice})>[];
      for (final a in alerts) {
        if (!a.enabled) continue;
        final p = priceBySymbol[a.symbol];
        if (p == null) continue;
        if (a.lastTriggeredAt != null &&
            DateTime.now().difference(a.lastTriggeredAt!) <
                const Duration(hours: 4)) {
          continue;
        }
        if (a.isTriggered(p)) {
          // 標記觸發
          await HiveService.instance.priceAlerts.put(
            a.id,
            a.copyWith(lastTriggeredAt: DateTime.now()),
          );
          hits.add((alert: a, currentPrice: p));
        }
      }
      // 7. 發通知
      if (hits.length == 1) {
        await NotificationService.instance.showPriceAlert(
          alert: hits.first.alert,
          currentPrice: hits.first.currentPrice,
        );
      } else if (hits.length > 1) {
        await NotificationService.instance.showBulkAlerts(hits);
      }
      return true;
    } catch (_) {
      return false;
    }
  });
}

/// 對 workmanager 排程的包裝
class BackgroundScheduler {
  BackgroundScheduler._();
  static final BackgroundScheduler instance = BackgroundScheduler._();

  bool _initialised = false;

  /// 在 main() 中呼叫一次
  Future<void> init() async {
    if (_initialised) return;
    await Workmanager().initialize(backgroundCallbackDispatcher);
    _initialised = true;
  }

  /// 套用使用者設定 (註冊或取消週期任務)
  Future<void> apply(BackgroundRefreshSettings s) async {
    await Workmanager().cancelByUniqueName(backgroundRefreshTaskName);
    if (!s.enabled) return;
    final freq = switch (s.interval) {
      BackgroundInterval.off => const Duration(minutes: 15),
      BackgroundInterval.m15 => const Duration(minutes: 15),
      BackgroundInterval.m30 => const Duration(minutes: 30),
      BackgroundInterval.h1 => const Duration(hours: 1),
      BackgroundInterval.h3 => const Duration(hours: 3),
    };
    await Workmanager().registerPeriodicTask(
      backgroundRefreshTaskName,
      backgroundRefreshTaskName,
      frequency: freq,
      constraints: Constraints(
        networkType:
            s.wifiOnly ? NetworkType.unmetered : NetworkType.connected,
      ),
      // 已先 cancelByUniqueName，這裡不需要設 existingPolicy
    );
  }
}
