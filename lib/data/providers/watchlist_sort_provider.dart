import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/hive_service.dart';

enum WatchlistSort {
  custom,      // 加入順序
  symbolAsc,   // 代號小→大
  nameAsc,     // 名稱注音
  changeDesc,  // 漲幅大→小
  changeAsc,   // 跌幅大→小
}

extension WatchlistSortLabel on WatchlistSort {
  String get label => switch (this) {
        WatchlistSort.custom => '自訂',
        WatchlistSort.symbolAsc => '代號',
        WatchlistSort.nameAsc => '名稱',
        WatchlistSort.changeDesc => '漲幅',
        WatchlistSort.changeAsc => '跌幅',
      };
  String get _key => switch (this) {
        WatchlistSort.custom => 'custom',
        WatchlistSort.symbolAsc => 'symbol_asc',
        WatchlistSort.nameAsc => 'name_asc',
        WatchlistSort.changeDesc => 'change_desc',
        WatchlistSort.changeAsc => 'change_asc',
      };
}

WatchlistSort _fromKey(String? k) => switch (k) {
      'symbol_asc' => WatchlistSort.symbolAsc,
      'name_asc' => WatchlistSort.nameAsc,
      'change_desc' => WatchlistSort.changeDesc,
      'change_asc' => WatchlistSort.changeAsc,
      _ => WatchlistSort.custom,
    };

class WatchlistSortNotifier extends Notifier<WatchlistSort> {
  static const _settingsKey = 'watchlist_sort';

  @override
  WatchlistSort build() {
    final box = HiveService.instance.settings;
    return _fromKey(box.get(_settingsKey) as String?);
  }

  void set(WatchlistSort sort) {
    final box = HiveService.instance.settings;
    box.put(_settingsKey, sort._key);
    state = sort;
  }
}

final watchlistSortProvider =
    NotifierProvider<WatchlistSortNotifier, WatchlistSort>(
        WatchlistSortNotifier.new);
