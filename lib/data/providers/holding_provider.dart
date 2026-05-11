import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/holding.dart';
import '../services/hive_service.dart';

class HoldingNotifier extends Notifier<List<Holding>> {
  @override
  List<Holding> build() {
    return HiveService.instance.holdings.values.toList()
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
  }

  void upsert(Holding h) {
    HiveService.instance.holdings.put(h.symbol, h);
    state = HiveService.instance.holdings.values.toList()
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
  }

  void remove(String symbol) {
    HiveService.instance.holdings.delete(symbol);
    state = HiveService.instance.holdings.values.toList()
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
  }

  Holding? bySymbol(String symbol) =>
      HiveService.instance.holdings.get(symbol);
}

final holdingsProvider =
    NotifierProvider<HoldingNotifier, List<Holding>>(HoldingNotifier.new);
