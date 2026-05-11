import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/providers.dart';
import '../theme/app_theme.dart';

/// 包在實際內容外層；若啟用了生物識別就先擋住，驗證後解鎖
class BiometricGate extends ConsumerStatefulWidget {
  final Widget child;
  const BiometricGate({super.key, required this.child});

  @override
  ConsumerState<BiometricGate> createState() => _BiometricGateState();
}

class _BiometricGateState extends ConsumerState<BiometricGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(biometricProvider.notifier).unlock();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(biometricProvider);
    if (s.unlocked) return widget.child;
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline,
                size: 56, color: AppTheme.accent),
            const SizedBox(height: 14),
            const Text(
              '請驗證身分',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.fingerprint),
              label: const Text('使用生物識別解鎖'),
              onPressed: () =>
                  ref.read(biometricProvider.notifier).unlock(),
            ),
          ],
        ),
      ),
    );
  }
}
