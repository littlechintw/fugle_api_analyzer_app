import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'data/providers/providers.dart';
import 'features/dashboard/dashboard_page.dart';
import 'features/onboarding/onboarding_page.dart';

class FugleApp extends ConsumerStatefulWidget {
  const FugleApp({super.key});

  @override
  ConsumerState<FugleApp> createState() => _FugleAppState();
}

class _FugleAppState extends ConsumerState<FugleApp> {
  bool _onboardingDone = isOnboardingDone();

  @override
  Widget build(BuildContext context) {
    ref.watch(tradeColorModeProvider);
    return MaterialApp(
      title: '股市技術分析',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: _onboardingDone
          ? const DashboardPage()
          : OnboardingPage(
              onComplete: () => setState(() => _onboardingDone = true),
            ),
    );
  }
}
