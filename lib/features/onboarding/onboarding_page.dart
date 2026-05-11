import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/services/hive_service.dart';

const _onboardingKey = 'onboarding_completed_v1';

bool isOnboardingDone() {
  return HiveService.instance.settings.get(_onboardingKey) as bool? ?? false;
}

Future<void> markOnboardingDone() async {
  await HiveService.instance.settings.put(_onboardingKey, true);
}

class OnboardingPage extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingPage({super.key, required this.onComplete});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _ctrl = PageController();
  int _index = 0;

  static const _slides = [
    _Slide(
      icon: Icons.candlestick_chart,
      title: '專業的技術分析',
      subtitle: '即時 K 線、5/10/20/60 MA、布林通道、\n'
          'BIAS / RSI / MACD / KD / W%R 副圖',
      hint: '所有指標於本地計算，速度快、省 API 額度',
    ),
    _Slide(
      icon: Icons.vpn_key_outlined,
      title: '需要 Fugle API Token',
      subtitle: '本 App 採用 Fugle Market Data API，\n請先到 developer.fugle.tw 申請免費金鑰',
      hint: 'Token 會加密儲存於裝置 Keystore，不會上傳',
      detail: [
        '1. 註冊 / 登入 富果會員',
        '2. 進入「金鑰申請」頁',
        '3. 建立金鑰，複製到本 App 的「設定」',
      ],
    ),
    _Slide(
      icon: Icons.bookmark_added_outlined,
      title: '加入您的自選股',
      subtitle: '搜尋代號或名稱，一鍵加入。\n支援漲跌排序、群組管理、價格警示',
      hint: '長按卡片可快速移除',
    ),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_index < _slides.length - 1) {
      _ctrl.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await markOnboardingDone();
    if (mounted) widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text('略過',
                    style: TextStyle(color: AppTheme.textSecondary)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => _slides[i],
              ),
            ),
            // 指示點
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _slides.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _index == i ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _index == i
                          ? AppTheme.accent
                          : AppTheme.borderColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        _index == _slides.length - 1 ? '開始使用' : '下一步',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String hint;
  final List<String>? detail;

  const _Slide({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.hint,
    this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 60, color: AppTheme.accent),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          if (detail != null) ...[
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final s in detail!)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Text(
                        s,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lightbulb_outline,
                    size: 12, color: AppTheme.accent),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    hint,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.accent,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
