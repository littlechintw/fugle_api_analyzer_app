import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 全域 in-flight API 計數器。
/// ApiLogInterceptor 在 onRequest 時呼叫 `increment`，
/// 在 onResponse/onError 時呼叫 `decrement`。
/// UI 用 `ref.watch(networkActivityProvider) > 0` 判斷是否顯示載入條。
class NetworkActivityNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void increment() => state = state + 1;
  void decrement() {
    final next = state - 1;
    state = next < 0 ? 0 : next;
  }
}

final networkActivityProvider =
    NotifierProvider<NetworkActivityNotifier, int>(NetworkActivityNotifier.new);
