import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/watchlist_group.dart';
import '../services/hive_service.dart';

/// 自選股分組管理 + 每檔股票的歸屬
///
/// 歸屬資訊存在 settings box 的單一 key 下：
///   `watchlist_group_assignment` → Map<symbol, groupId>
class WatchlistGroupNotifier extends Notifier<List<WatchlistGroup>> {
  static const _assignmentKey = 'watchlist_group_assignment';
  static const _selectedKey = 'watchlist_selected_group';

  @override
  List<WatchlistGroup> build() {
    final box = HiveService.instance.watchlistGroups;
    final list = box.values.toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  /// 新增群組
  void create(String name, int colorValue) {
    final id = 'g_${DateTime.now().millisecondsSinceEpoch}';
    final order = state.isEmpty
        ? 0
        : state.map((g) => g.sortOrder).reduce((a, b) => a > b ? a : b) + 1;
    final g = WatchlistGroup(
      id: id,
      name: name,
      sortOrder: order,
      colorValue: colorValue,
    );
    HiveService.instance.watchlistGroups.put(id, g);
    state = HiveService.instance.watchlistGroups.values.toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  void rename(String id, String name) {
    final box = HiveService.instance.watchlistGroups;
    final g = box.get(id);
    if (g == null) return;
    box.put(id, g.copyWith(name: name));
    state = box.values.toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  void remove(String id) {
    HiveService.instance.watchlistGroups.delete(id);
    // 把該群組成員移到「全部」(等同清掉 assignment)
    final assign = _readAssignment();
    assign.removeWhere((_, v) => v == id);
    _writeAssignment(assign);
    state = HiveService.instance.watchlistGroups.values.toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  /// 把某檔股票歸到某群組 (groupId == allGroupId 等同移除歸屬)
  void assign(String symbol, String groupId) {
    final assign = _readAssignment();
    if (groupId == WatchlistGroup.allGroupId) {
      assign.remove(symbol);
    } else {
      assign[symbol] = groupId;
    }
    _writeAssignment(assign);
    // 觸發 listeners (即使 state 內容不變)
    state = [...state];
  }

  /// 查一檔股票歸屬，未指定回 allGroupId
  String groupIdOf(String symbol) {
    final assign = _readAssignment();
    return assign[symbol] ?? WatchlistGroup.allGroupId;
  }

  /// 目前選擇的 tab
  String currentSelected() {
    final v = HiveService.instance.settings.get(_selectedKey) as String?;
    return v ?? WatchlistGroup.allGroupId;
  }

  void selectGroup(String id) {
    HiveService.instance.settings.put(_selectedKey, id);
    state = [...state]; // refresh subscribers
  }

  Map<String, String> _readAssignment() {
    final raw = HiveService.instance.settings.get(_assignmentKey);
    if (raw is Map) {
      return Map<String, String>.from(
        raw.map((k, v) => MapEntry(k.toString(), v.toString())),
      );
    }
    return {};
  }

  void _writeAssignment(Map<String, String> m) {
    HiveService.instance.settings.put(_assignmentKey, m);
  }
}

final watchlistGroupsProvider =
    NotifierProvider<WatchlistGroupNotifier, List<WatchlistGroup>>(
        WatchlistGroupNotifier.new);

/// 目前選的群組 ID
final selectedGroupProvider = StateProvider<String>((ref) {
  ref.watch(watchlistGroupsProvider); // 為了拿到 notifier 已 init
  return WatchlistGroup.allGroupId;
});
