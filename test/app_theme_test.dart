import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fugle_api_app/core/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    setUp(() {
      // 確保每個測試從 redUp 開始
      AppTheme.applyMode(TrendColorMode.redUp);
    });

    test('redUp: bullish 紅 / bearish 綠', () {
      AppTheme.applyMode(TrendColorMode.redUp);
      expect(AppTheme.bullish, const Color(0xFFE53E3E));
      expect(AppTheme.bearish, const Color(0xFF38A169));
      expect(AppTheme.colorMode, TrendColorMode.redUp);
    });

    test('greenUp: 顏色顛倒', () {
      AppTheme.applyMode(TrendColorMode.greenUp);
      expect(AppTheme.bullish, const Color(0xFF38A169));
      expect(AppTheme.bearish, const Color(0xFFE53E3E));
      expect(AppTheme.colorMode, TrendColorMode.greenUp);
    });

    test('trendColor: 正/負/零 對應 bullish/bearish/neutral', () {
      AppTheme.applyMode(TrendColorMode.redUp);
      expect(AppTheme.trendColor(5), AppTheme.bullish);
      expect(AppTheme.trendColor(-3), AppTheme.bearish);
      expect(AppTheme.trendColor(0), AppTheme.neutral);
    });

    test('dark 主題回傳合法 ThemeData', () {
      final theme = AppTheme.dark;
      expect(theme, isA<ThemeData>());
      expect(theme.scaffoldBackgroundColor, AppTheme.bgPrimary);
      // 紅漲模式下 error 用 bullish (紅)
      expect(theme.colorScheme.error, AppTheme.bullish);
    });

    test('靜態常數顏色不為透明', () {
      expect(AppTheme.accent.alpha, isNonZero);
      expect(AppTheme.bgPrimary.alpha, isNonZero);
      expect(AppTheme.bgCard.alpha, isNonZero);
      expect(AppTheme.borderColor.alpha, isNonZero);
      expect(AppTheme.textPrimary.alpha, isNonZero);
      expect(AppTheme.textSecondary.alpha, isNonZero);
      expect(AppTheme.neutral.alpha, isNonZero);
    });
  });
}
