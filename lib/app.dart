import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'data/providers/providers.dart';
import 'features/dashboard/dashboard_page.dart';

class FugleApp extends ConsumerWidget {
  const FugleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 訂閱配色模式 — 切換時整顆 App 重繪以套用新色
    ref.watch(tradeColorModeProvider);
    return MaterialApp(
      title: '股市技術分析',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: const DashboardPage(),
    );
  }
}
