import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 內建的 shimmer 動畫 — 不依賴外部套件。
/// 用 AnimatedBuilder + ShaderMask 把漸層帶橫向掃過子元件。
class Shimmer extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Color baseColor;
  final Color highlightColor;

  const Shimmer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1300),
    this.baseColor = AppTheme.bgSurface,
    this.highlightColor = AppTheme.bgCard,
  });

  /// 工廠：產生一塊純色 placeholder 用的 shimmer
  factory Shimmer.box({
    double? width,
    double? height,
    BorderRadius? borderRadius,
  }) {
    return Shimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppTheme.bgSurface,
          borderRadius: borderRadius ?? BorderRadius.circular(4),
        ),
      ),
    );
  }

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) {
          final t = _ctrl.value;
          // 從 -1 → 2 移動，讓亮帶從左掃到右
          final dx = (t * 3) - 1;
          return LinearGradient(
            begin: const Alignment(-1, 0),
            end: const Alignment(1, 0),
            colors: [
              widget.baseColor,
              widget.highlightColor,
              widget.baseColor,
            ],
            stops: [
              (dx - 0.3).clamp(0, 1),
              dx.clamp(0, 1),
              (dx + 0.3).clamp(0, 1),
            ],
          ).createShader(bounds);
        },
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// 預設的卡片骨架 — 直接拿來當 loading placeholder
class ShimmerCardPlaceholder extends StatelessWidget {
  final double height;
  const ShimmerCardPlaceholder({super.key, this.height = 64});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      padding: const EdgeInsets.all(14),
      child: Shimmer(
        child: Row(
          children: [
            Container(
              width: 60,
              height: 14,
              color: AppTheme.bgSurface,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    height: 10,
                    color: AppTheme.bgSurface,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 80,
                    height: 8,
                    color: AppTheme.bgSurface,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 60,
              height: 14,
              color: AppTheme.bgSurface,
            ),
          ],
        ),
      ),
    );
  }
}
