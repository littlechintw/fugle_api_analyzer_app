import 'package:flutter/material.dart';

/// 可調整的漲跌配色模式
enum TrendColorMode {
  /// 台股慣例：紅漲綠跌
  redUp,
  /// 美股 / 大部分海外市場：綠漲紅跌
  greenUp,
}

/// 專業交易軟體風格的深色主題
class AppTheme {
  // 顏色常數
  static const Color _red = Color(0xFFE53E3E);
  static const Color _green = Color(0xFF38A169);
  static const Color neutral = Color(0xFFA0AEC0);

  // 動態漲跌色 — 由 tradeColorModeProvider 控制；改動後所有 Consumer 重繪
  static Color _bullish = _red;
  static Color _bearish = _green;
  static TrendColorMode _mode = TrendColorMode.redUp;

  static Color get bullish => _bullish;
  static Color get bearish => _bearish;
  static TrendColorMode get colorMode => _mode;

  /// 由 provider 呼叫 — 一般 UI 不要直接呼叫
  static void applyMode(TrendColorMode mode) {
    _mode = mode;
    if (mode == TrendColorMode.redUp) {
      _bullish = _red;
      _bearish = _green;
    } else {
      _bullish = _green;
      _bearish = _red;
    }
  }

  static const Color bgPrimary = Color(0xFF0E1116);
  static const Color bgSurface = Color(0xFF161B22);
  static const Color bgCard = Color(0xFF1C232E);
  static const Color borderColor = Color(0xFF2A3340);
  static const Color textPrimary = Color(0xFFE6EDF3);
  static const Color textSecondary = Color(0xFF8B98A7);
  static const Color accent = Color(0xFFFFB020);

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: bgPrimary,
      colorScheme: ColorScheme.dark(
        surface: bgSurface,
        primary: accent,
        secondary: accent,
        onSurface: textPrimary,
        error: bullish,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgSurface,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: borderColor),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: borderColor,
        space: 1,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: accent),
        ),
        hintStyle: const TextStyle(color: textSecondary),
        labelStyle: const TextStyle(color: textSecondary),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  /// 根據漲跌幅取得顏色
  static Color trendColor(double change) {
    if (change > 0) return bullish;
    if (change < 0) return bearish;
    return neutral;
  }
}
