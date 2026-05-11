import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../services/hive_service.dart';

/// 漲跌配色設定。
///
/// 改動時：
/// 1. 寫回 Hive (settings_box key = 'trend_color_mode')
/// 2. 呼叫 [AppTheme.applyMode]
/// 3. state 變更 → 訂閱此 provider 的 widget 全部重繪 → 讀到新的 bullish/bearish
class TrendColorModeNotifier extends Notifier<TrendColorMode> {
  static const _key = 'trend_color_mode';

  @override
  TrendColorMode build() {
    final box = HiveService.instance.settings;
    final stored = box.get(_key) as String?;
    final mode = stored == 'green_up'
        ? TrendColorMode.greenUp
        : TrendColorMode.redUp;
    AppTheme.applyMode(mode);
    return mode;
  }

  void set(TrendColorMode mode) {
    final box = HiveService.instance.settings;
    box.put(_key, mode == TrendColorMode.greenUp ? 'green_up' : 'red_up');
    AppTheme.applyMode(mode);
    state = mode;
  }
}

final tradeColorModeProvider =
    NotifierProvider<TrendColorModeNotifier, TrendColorMode>(
        TrendColorModeNotifier.new);
