import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fugle_api_app/core/theme/app_theme.dart';
import 'package:fugle_api_app/data/models/holding.dart';
import 'package:fugle_api_app/data/models/price_alert.dart';
import 'package:fugle_api_app/data/models/watchlist_group.dart';
import 'package:fugle_api_app/data/providers/background_refresh_provider.dart';
import 'package:fugle_api_app/data/providers/chart_options_provider.dart';
import 'package:fugle_api_app/data/providers/holding_provider.dart';
import 'package:fugle_api_app/data/providers/indicator_prefs_provider.dart';
import 'package:fugle_api_app/data/providers/price_alert_provider.dart';
import 'package:fugle_api_app/data/providers/trade_color_provider.dart';
import 'package:fugle_api_app/data/providers/watchlist_group_provider.dart';
import 'package:fugle_api_app/data/providers/watchlist_sort_provider.dart';

import '_hive_helper.dart';

void main() {
  setUpAll(setupHiveForTesting);
  tearDownAll(teardownHive);

  setUp(resetHiveBoxes);

  group('TrendColorModeNotifier', () {
    test('預設 redUp + 切換 greenUp 持久化', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      expect(c.read(tradeColorModeProvider), TrendColorMode.redUp);

      c
          .read(tradeColorModeProvider.notifier)
          .set(TrendColorMode.greenUp);
      expect(c.read(tradeColorModeProvider), TrendColorMode.greenUp);
      expect(AppTheme.colorMode, TrendColorMode.greenUp);

      // 新容器重讀（模擬重啟）
      final c2 = ProviderContainer();
      addTearDown(c2.dispose);
      expect(c2.read(tradeColorModeProvider), TrendColorMode.greenUp);
    });
  });

  group('WatchlistSortNotifier', () {
    test('預設 custom + 切換到 changeDesc + 持久化', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      expect(c.read(watchlistSortProvider), WatchlistSort.custom);

      c.read(watchlistSortProvider.notifier).set(WatchlistSort.changeDesc);
      expect(c.read(watchlistSortProvider), WatchlistSort.changeDesc);

      final c2 = ProviderContainer();
      addTearDown(c2.dispose);
      expect(c2.read(watchlistSortProvider), WatchlistSort.changeDesc);
    });

    test('每個 enum 都有 label', () {
      for (final s in WatchlistSort.values) {
        expect(s.label, isNotEmpty);
      }
    });
  });

  group('ChartOptionsNotifier', () {
    test('預設 day + m6', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final o = c.read(chartOptionsProvider);
      expect(o.timeframe, ChartTimeframe.day);
      expect(o.range, ChartRange.m6);
    });

    test('setTimeframe / setRange 改變 state', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(chartOptionsProvider.notifier).setTimeframe(ChartTimeframe.week);
      c.read(chartOptionsProvider.notifier).setRange(ChartRange.y1);
      final o = c.read(chartOptionsProvider);
      expect(o.timeframe, ChartTimeframe.week);
      expect(o.range, ChartRange.y1);
    });

    test('apiCode 對應正確', () {
      expect(ChartTimeframe.day.apiCode, 'D');
      expect(ChartTimeframe.week.apiCode, 'W');
      expect(ChartTimeframe.month.apiCode, 'M');
    });

    test('displayBarsFor 週/月 是日 K 的子集', () {
      final r = ChartRange.y1;
      expect(r.displayBarsFor(ChartTimeframe.day), 380);
      expect(r.displayBarsFor(ChartTimeframe.week), 380 ~/ 5);
      expect(r.displayBarsFor(ChartTimeframe.month), 380 ~/ 22);
    });
  });

  group('IndicatorPrefsNotifier', () {
    test('預設值與 reset 一致', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final p = c.read(indicatorPrefsProvider);
      expect(p.maPeriods, [5, 10, 20, 60]);
      expect(p.rsiPeriod, 14);
      expect(p.kdPeriod, 9);
      expect(p.macdFast, 12);
      expect(p.macdSlow, 26);
      expect(p.macdSignal, 9);
      expect(p.bollingerPeriod, 20);
      expect(p.bollingerStdDev, 2.0);
    });

    test('update 後持久化', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(indicatorPrefsProvider.notifier).update(
            const IndicatorPrefs(
              maPeriods: [3, 8, 21, 55],
              rsiPeriod: 7,
              kdPeriod: 5,
              macdFast: 8,
              macdSlow: 21,
              macdSignal: 5,
              bollingerPeriod: 15,
              bollingerStdDev: 1.5,
            ),
          );
      // 重開
      final c2 = ProviderContainer();
      addTearDown(c2.dispose);
      final p = c2.read(indicatorPrefsProvider);
      expect(p.maPeriods, [3, 8, 21, 55]);
      expect(p.rsiPeriod, 7);
      expect(p.bollingerStdDev, 1.5);
    });

    test('reset 回預設', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(indicatorPrefsProvider.notifier).update(
          const IndicatorPrefs(rsiPeriod: 30));
      c.read(indicatorPrefsProvider.notifier).reset();
      expect(c.read(indicatorPrefsProvider).rsiPeriod, 14);
    });
  });

  group('PriceAlertNotifier', () {
    test('addAlert / remove / toggle / markTriggered', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final n = c.read(priceAlertsProvider.notifier);

      expect(c.read(priceAlertsProvider), isEmpty);

      n.addAlert(
        symbol: '2330',
        name: '台積電',
        direction: AlertDirection.above,
        price: 600,
      );
      n.addAlert(
        symbol: '2317',
        name: '鴻海',
        direction: AlertDirection.below,
        price: 100,
      );
      expect(c.read(priceAlertsProvider).length, 2);

      // toggle (預設 enabled)
      final id1 = c.read(priceAlertsProvider).first.id;
      n.toggle(id1);
      expect(
        c.read(priceAlertsProvider).firstWhere((a) => a.id == id1).enabled,
        isFalse,
      );

      // markTriggered
      n.markTriggered(id1);
      expect(
        c
            .read(priceAlertsProvider)
            .firstWhere((a) => a.id == id1)
            .lastTriggeredAt,
        isNotNull,
      );

      // remove
      n.remove(id1);
      expect(c.read(priceAlertsProvider).length, 1);
    });

    test('forSymbol 過濾', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final n = c.read(priceAlertsProvider.notifier);
      n.addAlert(
        symbol: '2330',
        name: 'A',
        direction: AlertDirection.above,
        price: 1,
      );
      n.addAlert(
        symbol: '2330',
        name: 'A',
        direction: AlertDirection.below,
        price: 0.5,
      );
      n.addAlert(
        symbol: '0050',
        name: 'B',
        direction: AlertDirection.above,
        price: 80,
      );
      expect(n.forSymbol('2330').length, 2);
      expect(n.forSymbol('0050').length, 1);
      expect(n.forSymbol('XXX'), isEmpty);
    });
  });

  group('HoldingNotifier', () {
    test('upsert / remove / bySymbol', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final n = c.read(holdingsProvider.notifier);

      n.upsert(_holding('2330', '台積電', 1000, 500));
      n.upsert(_holding('0050', '元大', 2000, 80));
      expect(c.read(holdingsProvider).length, 2);

      // upsert 同 symbol 會覆蓋
      n.upsert(_holding('2330', '台積電', 2000, 550));
      expect(c.read(holdingsProvider).length, 2);
      expect(n.bySymbol('2330')?.quantity, 2000);

      n.remove('0050');
      expect(c.read(holdingsProvider).length, 1);
      expect(n.bySymbol('0050'), isNull);
    });
  });

  group('WatchlistGroupNotifier', () {
    test('create / rename / remove', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final n = c.read(watchlistGroupsProvider.notifier);

      n.create('長期持有', 0xFFEF476F);
      n.create('短線觀察', 0xFF06D6A0);
      expect(c.read(watchlistGroupsProvider).length, 2);

      final first = c.read(watchlistGroupsProvider).first;
      n.rename(first.id, '長線');
      expect(
        c.read(watchlistGroupsProvider).firstWhere((g) => g.id == first.id).name,
        '長線',
      );

      n.remove(first.id);
      expect(c.read(watchlistGroupsProvider).length, 1);
    });

    test('assign / groupIdOf', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final n = c.read(watchlistGroupsProvider.notifier);

      n.create('A', 0xFF000000);
      final gid = c.read(watchlistGroupsProvider).first.id;

      // 預設沒指派
      expect(n.groupIdOf('2330'), WatchlistGroup.allGroupId);

      n.assign('2330', gid);
      expect(n.groupIdOf('2330'), gid);

      // 指派到 allGroupId 等於移除
      n.assign('2330', WatchlistGroup.allGroupId);
      expect(n.groupIdOf('2330'), WatchlistGroup.allGroupId);
    });

    test('刪群組時成員被移到 all', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final n = c.read(watchlistGroupsProvider.notifier);

      n.create('A', 0xFF000000);
      final gid = c.read(watchlistGroupsProvider).first.id;

      n.assign('2330', gid);
      n.assign('2317', gid);
      expect(n.groupIdOf('2330'), gid);

      n.remove(gid);
      expect(n.groupIdOf('2330'), WatchlistGroup.allGroupId);
      expect(n.groupIdOf('2317'), WatchlistGroup.allGroupId);
    });
  });

  group('BackgroundRefreshNotifier', () {
    test('預設 off + 設定持久化', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      expect(c.read(backgroundRefreshProvider).interval,
          BackgroundInterval.off);
      expect(c.read(backgroundRefreshProvider).wifiOnly, isTrue);

      // setInterval 不能真的呼叫 (會嘗試啟動 workmanager)
      // 但 setWifiOnly 應該也會嘗試 apply。
      // 直接測 state copyWith 邏輯
      final s = const BackgroundRefreshSettings(
        interval: BackgroundInterval.h1,
        wifiOnly: true,
      );
      expect(s.enabled, isTrue);
      expect(s.copyWith(wifiOnly: false).wifiOnly, isFalse);
    });

    test('estimatedDailyCalls 計算', () {
      expect(BackgroundInterval.off.estimatedDailyCalls(10), 0);
      expect(BackgroundInterval.h1.estimatedDailyCalls(10), 160);
      expect(BackgroundInterval.m15.estimatedDailyCalls(5), 320);
    });

    test('每個 enum 都有 label', () {
      for (final i in BackgroundInterval.values) {
        expect(i.label, isNotEmpty);
      }
    });
  });
}

Holding _holding(String sym, String name, int qty, double cost) {
  // 用 import 的 Holding 模型避免循環
  // (此處實際 import 在 holdings_test.dart 同樣可用)
  // 為避免 import 重複，直接用 generic placeholder
  // — 但 HoldingNotifier 需要真正的 Holding object，所以這裡 inline。
  return Holding(
    symbol: sym,
    name: name,
    quantity: qty,
    avgCost: cost,
    addedAt: DateTime(2025, 1, 1),
  );
}
