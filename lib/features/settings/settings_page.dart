import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_error.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/providers/providers.dart';
import '../../data/providers/trade_color_provider.dart';
import 'watchlist_backup.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late final TextEditingController _tokenCtrl;
  bool _obscure = true;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _tokenCtrl = TextEditingController();
    // 首次載入時填入
    Future.microtask(() async {
      final t = await ref.read(secureStorageProvider).readToken();
      if (t != null && mounted) {
        _tokenCtrl.text = t;
      }
    });
  }

  @override
  void dispose() {
    _tokenCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(apiStatsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('Fugle API'),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'API Token',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _tokenCtrl,
                    obscureText: _obscure,
                    onChanged: (_) => setState(() => _dirty = true),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      letterSpacing: 0.5,
                    ),
                    decoration: InputDecoration(
                      hintText: '貼上您的 Fugle API Token',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18,
                        ),
                        onPressed: () =>
                            setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save_outlined, size: 18),
                        label: const Text('儲存並驗證'),
                        onPressed: _dirty
                            ? () async {
                                await ref
                                    .read(apiTokenProvider.notifier)
                                    .save(_tokenCtrl.text);
                                setState(() => _dirty = false);
                              }
                            : null,
                      ),
                      const SizedBox(width: 12),
                      TextButton.icon(
                        icon: const Icon(Icons.delete_outline,
                            size: 18, color: AppTheme.textSecondary),
                        label: const Text('清除',
                            style:
                                TextStyle(color: AppTheme.textSecondary)),
                        onPressed: () async {
                          await ref.read(apiTokenProvider.notifier).clear();
                          _tokenCtrl.clear();
                          setState(() => _dirty = false);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _TokenStatusBadge(),
                  const SizedBox(height: 6),
                  const Text(
                    'Token 使用 flutter_secure_storage 加密儲存於裝置 Keystore，不會以明碼形式留存。',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _section('API 監控'),
          stats.when(
            data: (s) => Column(
              children: [
                Row(
                  children: [
                    _StatCardHelper.build('今日呼叫', s.today.toString()),
                    const SizedBox(width: 8),
                    _StatCardHelper.build('近 7 日', s.last7Days.toString()),
                    const SizedBox(width: 8),
                    _StatCardHelper.build('累計', s.total.toString()),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _StatCardHelper.build(
                      '今日成功',
                      s.todaySuccess.toString(),
                      color: AppTheme.bearish,
                    ),
                    const SizedBox(width: 8),
                    _StatCardHelper.build(
                      '今日失敗',
                      s.todayFailure.toString(),
                      color: AppTheme.bullish,
                    ),
                    const SizedBox(width: 8),
                    _StatCardHelper.build(
                      '累計成功率',
                      s.total == 0
                          ? '—'
                          : '${(s.successRate * 100).toStringAsFixed(1)}%',
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '最近呼叫紀錄',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (s.recent.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              '尚無 API 呼叫紀錄',
                              style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13),
                            ),
                          )
                        else
                          ...s.recent.take(20).map(
                                (l) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Icon(
                                        l.success
                                            ? Icons.check_circle
                                            : Icons.error,
                                        size: 12,
                                        color: l.success
                                            ? AppTheme.bearish
                                            : AppTheme.bullish,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          '${l.method} ${l.path}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        Fmt.datetime(l.timestamp),
                                        style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('讀取統計失敗：$e'),
          ),
          const SizedBox(height: 24),
          _section('自選股備份'),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '透過剪貼簿備份自選股清單，可貼到備忘錄或傳到新手機後再貼回此處匯入。',
                    style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        height: 1.5),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.upload_outlined, size: 18),
                        label: const Text('匯出到剪貼簿'),
                        onPressed: () => exportWatchlist(context, ref),
                      ),
                      const SizedBox(width: 12),
                      TextButton.icon(
                        icon: const Icon(Icons.download_outlined,
                            size: 18, color: AppTheme.accent),
                        label: const Text(
                          '從剪貼簿匯入',
                          style: TextStyle(color: AppTheme.accent),
                        ),
                        onPressed: () => importWatchlist(context, ref),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _section('外觀'),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '漲跌配色',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _ColorModeOption(
                          mode: TrendColorMode.redUp,
                          label: '紅漲綠跌',
                          subtitle: '台股慣例',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ColorModeOption(
                          mode: TrendColorMode.greenUp,
                          label: '綠漲紅跌',
                          subtitle: '美股 / 海外慣例',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _section('關於'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '股市技術分析 v0.1.0',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Flutter · Riverpod · Hive · Fugle API\n本 App 為技術分析工具，所有指標僅供參考，不構成投資建議。',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
        child: Text(
          title,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

}

class _TokenStatusBadge extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(apiTokenProvider);
    return async.when(
      data: (s) {
        if (!s.hasToken) {
          return const Row(
            children: [
              Icon(Icons.info_outline,
                  size: 14, color: AppTheme.textSecondary),
              SizedBox(width: 6),
              Text(
                '尚未填寫 Token',
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 11),
              ),
            ],
          );
        }
        switch (s.validity) {
          case TokenValidity.unchecked:
            return const Row(
              children: [
                Icon(Icons.help_outline,
                    size: 14, color: AppTheme.textSecondary),
                SizedBox(width: 6),
                Text(
                  '尚未驗證，按「儲存並驗證」確認 Token 有效',
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 11),
                ),
              ],
            );
          case TokenValidity.verifying:
            return const Row(
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                      strokeWidth: 1.6, color: AppTheme.accent),
                ),
                SizedBox(width: 8),
                Text(
                  '驗證中…',
                  style: TextStyle(color: AppTheme.accent, fontSize: 11),
                ),
              ],
            );
          case TokenValidity.valid:
            return const Row(
              children: [
                Icon(Icons.check_circle,
                    size: 14, color: AppTheme.bearish),
                SizedBox(width: 6),
                Text(
                  'Token 驗證通過',
                  style: TextStyle(
                      color: AppTheme.bearish,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ],
            );
          case TokenValidity.invalid:
            return Row(
              children: [
                const Icon(Icons.error,
                    size: 14, color: AppTheme.bullish),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    s.errorMessage == null
                        ? 'Token 驗證失敗'
                        : 'Token 驗證失敗：${AppError.from(Exception(s.errorMessage!)).userMessage}',
                    style: const TextStyle(
                      color: AppTheme.bullish,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
        }
      },
      loading: () => const SizedBox(
        height: 14,
        width: 14,
        child: CircularProgressIndicator(strokeWidth: 1.5),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _ColorModeOption extends ConsumerWidget {
  final TrendColorMode mode;
  final String label;
  final String subtitle;
  const _ColorModeOption({
    required this.mode,
    required this.label,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(tradeColorModeProvider);
    final selected = current == mode;
    final upColor = mode == TrendColorMode.redUp
        ? const Color(0xFFE53E3E)
        : const Color(0xFF38A169);
    final downColor = mode == TrendColorMode.redUp
        ? const Color(0xFF38A169)
        : const Color(0xFFE53E3E);
    return InkWell(
      onTap: () =>
          ref.read(tradeColorModeProvider.notifier).set(mode),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: AppTheme.bgSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppTheme.accent : AppTheme.borderColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: upColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: downColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Spacer(),
                if (selected)
                  const Icon(Icons.check_circle,
                      size: 16, color: AppTheme.accent),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCardHelper {
  static Widget build(String label, String value, {Color? color}) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: color ?? AppTheme.accent,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
