import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/hive_service.dart';

enum BackgroundInterval { off, m15, m30, h1, h3 }

extension BackgroundIntervalMeta on BackgroundInterval {
  String get label => switch (this) {
        BackgroundInterval.off => '關閉',
        BackgroundInterval.m15 => '每 15 分鐘',
        BackgroundInterval.m30 => '每 30 分鐘',
        BackgroundInterval.h1 => '每 1 小時',
        BackgroundInterval.h3 => '每 3 小時',
      };

  /// 估算一日呼叫次數 (16 小時清醒)
  int estimatedDailyCalls(int watchlistCount) {
    final wakeUps = switch (this) {
          BackgroundInterval.off => 0,
          BackgroundInterval.m15 => 64,
          BackgroundInterval.m30 => 32,
          BackgroundInterval.h1 => 16,
          BackgroundInterval.h3 => 6,
        };
    return wakeUps * watchlistCount;
  }
}

class BackgroundRefreshSettings {
  final BackgroundInterval interval;
  final bool wifiOnly;
  const BackgroundRefreshSettings({
    required this.interval,
    required this.wifiOnly,
  });

  bool get enabled => interval != BackgroundInterval.off;

  BackgroundRefreshSettings copyWith({
    BackgroundInterval? interval,
    bool? wifiOnly,
  }) {
    return BackgroundRefreshSettings(
      interval: interval ?? this.interval,
      wifiOnly: wifiOnly ?? this.wifiOnly,
    );
  }
}

class BackgroundRefreshNotifier
    extends Notifier<BackgroundRefreshSettings> {
  static const _intervalKey = 'bg_refresh_interval';
  static const _wifiKey = 'bg_refresh_wifi_only';

  @override
  BackgroundRefreshSettings build() {
    final box = HiveService.instance.settings;
    final stored = box.get(_intervalKey) as String? ?? 'off';
    final wifi = box.get(_wifiKey) as bool? ?? true;
    return BackgroundRefreshSettings(
      interval: BackgroundInterval.values.firstWhere(
        (e) => e.name == stored,
        orElse: () => BackgroundInterval.off,
      ),
      wifiOnly: wifi,
    );
  }

  void setInterval(BackgroundInterval interval) {
    HiveService.instance.settings.put(_intervalKey, interval.name);
    state = state.copyWith(interval: interval);
    // TODO: 註冊 / 取消 workmanager / BGTaskScheduler 排程
  }

  void setWifiOnly(bool v) {
    HiveService.instance.settings.put(_wifiKey, v);
    state = state.copyWith(wifiOnly: v);
  }
}

final backgroundRefreshProvider = NotifierProvider<BackgroundRefreshNotifier,
    BackgroundRefreshSettings>(BackgroundRefreshNotifier.new);
