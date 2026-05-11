import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/price_alert.dart';

/// 系統通知服務 — 支援 Android Material 3 rich style
///
/// Channel 設計:
///   - `price_alerts`     高重要度，價格警示專用
///   - `market_updates`   一般重要度，市場熱度提醒
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialised = false;

  Future<void> init() async {
    if (_initialised) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);

    // 主動建立 channel (Android 8+ 需要)
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        'price_alerts',
        '價格警示',
        description: '您設定的股價觸發通知',
        importance: Importance.high,
        enableVibration: true,
      ),
    );
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        'market_updates',
        '市場提醒',
        description: '大盤 / 自選股一般更新',
        importance: Importance.defaultImportance,
      ),
    );
    // Android 13+ 需要明確 runtime permission
    await androidImpl?.requestNotificationsPermission();

    _initialised = true;
  }

  /// 單一價格警示通知 (一檔股票觸發時)
  Future<void> showPriceAlert({
    required PriceAlert alert,
    required double currentPrice,
  }) async {
    final color = alert.direction == AlertDirection.above
        ? Colors.red
        : Colors.green;
    final title = '🔔 ${alert.name} (${alert.symbol})';
    final body =
        '已 ${alert.directionLabel} ${alert.price.toStringAsFixed(2)} 元，'
        '現價 ${currentPrice.toStringAsFixed(2)}';

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'price_alerts',
        '價格警示',
        channelDescription: '您設定的股價觸發通知',
        importance: Importance.high,
        priority: Priority.high,
        color: color,
        colorized: true,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(body),
        category: AndroidNotificationCategory.alarm,
      ),
    );
    await _plugin.show(
      alert.id.hashCode,
      title,
      body,
      details,
    );
  }

  /// 多檔同時觸發 → 用 Inbox 樣式顯示一筆彙整通知
  Future<void> showBulkAlerts(
      List<({PriceAlert alert, double currentPrice})> hits) async {
    if (hits.isEmpty) return;
    final lines = hits
        .take(8)
        .map((h) =>
            '${h.alert.name} ${h.alert.directionLabel} '
            '${h.alert.price.toStringAsFixed(2)}')
        .toList();
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'price_alerts',
        '價格警示',
        channelDescription: '您設定的股價觸發通知',
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: InboxStyleInformation(
          lines,
          contentTitle: '🔔 ${hits.length} 檔股票觸發警示',
          summaryText: '點擊查看詳情',
        ),
        icon: '@mipmap/ic_launcher',
      ),
    );
    await _plugin.show(
      'bulk_alerts'.hashCode,
      '🔔 ${hits.length} 檔股票觸發警示',
      lines.join('\n'),
      details,
    );
  }

  /// 背景刷新進度通知 (可選顯示)
  Future<void> showProgress({
    required int current,
    required int total,
    required String message,
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'market_updates',
        '市場提醒',
        channelDescription: '大盤 / 自選股一般更新',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        showProgress: true,
        maxProgress: total,
        progress: current,
        onlyAlertOnce: true,
        icon: '@mipmap/ic_launcher',
      ),
    );
    await _plugin.show(99001, '更新自選股報價', message, details);
  }

  Future<void> clearProgress() => _plugin.cancel(99001);
}
