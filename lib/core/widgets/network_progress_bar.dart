import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/providers.dart';
import '../theme/app_theme.dart';

/// 頂端網路活動進度條 — 只要有任何 API 呼叫進行中就顯示。
/// 使用 LinearProgressIndicator 的 indeterminate 動畫，
/// 高度極細不佔版面。
class NetworkProgressBar extends ConsumerWidget {
  const NetworkProgressBar({super.key, this.height = 2.5});

  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(networkActivityProvider) > 0;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: active
          ? SizedBox(
              height: height,
              child: const LinearProgressIndicator(
                minHeight: 2.5,
                backgroundColor: Colors.transparent,
                color: AppTheme.accent,
              ),
            )
          : SizedBox(height: height, key: const ValueKey('empty')),
    );
  }
}

/// 一個小型轉圈動畫，用於卡片內顯示載入中。
class TinySpinner extends StatelessWidget {
  const TinySpinner({super.key, this.size = 12, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 1.6,
        color: color ?? AppTheme.accent,
      ),
    );
  }
}
