import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/price_alert.dart';
import '../services/hive_service.dart';

class PriceAlertNotifier extends Notifier<List<PriceAlert>> {
  @override
  List<PriceAlert> build() {
    final box = HiveService.instance.priceAlerts;
    return box.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void addAlert({
    required String symbol,
    required String name,
    required AlertDirection direction,
    required double price,
  }) {
    final id = PriceAlert.makeId(symbol, direction, price);
    final alert = PriceAlert(
      id: id,
      symbol: symbol,
      name: name,
      direction: direction,
      price: price,
      createdAt: DateTime.now(),
    );
    HiveService.instance.priceAlerts.put(id, alert);
    state = HiveService.instance.priceAlerts.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void remove(String id) {
    HiveService.instance.priceAlerts.delete(id);
    state = HiveService.instance.priceAlerts.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void toggle(String id) {
    final box = HiveService.instance.priceAlerts;
    final a = box.get(id);
    if (a == null) return;
    box.put(id, a.copyWith(enabled: !a.enabled));
    state = box.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// 標記為「剛剛觸發」(避免短時間內重複通知)
  void markTriggered(String id) {
    final box = HiveService.instance.priceAlerts;
    final a = box.get(id);
    if (a == null) return;
    box.put(id, a.copyWith(lastTriggeredAt: DateTime.now()));
    state = box.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// 對單一 symbol 的警示
  List<PriceAlert> forSymbol(String symbol) {
    return state.where((a) => a.symbol == symbol).toList();
  }
}

final priceAlertsProvider =
    NotifierProvider<PriceAlertNotifier, List<PriceAlert>>(
        PriceAlertNotifier.new);
