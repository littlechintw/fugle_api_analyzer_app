import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/watchlist_item.dart';
import '../../data/providers/providers.dart';

/// 匯出自選股到剪貼簿（JSON 格式）
Future<void> exportWatchlist(BuildContext context, WidgetRef ref) async {
  final items = ref.read(watchlistProvider);
  final payload = {
    'version': 1,
    'exportedAt': DateTime.now().toIso8601String(),
    'items': items
        .map((w) => {
              'symbol': w.symbol,
              'name': w.name,
              'addedAt': w.addedAt.toIso8601String(),
            })
        .toList(),
  };
  final json = const JsonEncoder.withIndent('  ').convert(payload);
  await Clipboard.setData(ClipboardData(text: json));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('已將 ${items.length} 檔自選股複製到剪貼簿'),
      action: SnackBarAction(
        label: '預覽',
        onPressed: () => _showPreview(context, json),
      ),
    ),
  );
}

void _showPreview(BuildContext context, String json) {
  showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: AppTheme.bgCard,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 500),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '匯出內容',
                style: TextStyle(
                  color: AppTheme.accent,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(
                    json,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('關閉'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// 從剪貼簿匯入自選股
Future<void> importWatchlist(BuildContext context, WidgetRef ref) async {
  final data = await Clipboard.getData('text/plain');
  if (data == null || data.text == null || data.text!.isEmpty) {
    if (!context.mounted) return;
    _showError(context, '剪貼簿是空的，請先複製備份 JSON');
    return;
  }

  try {
    final json = jsonDecode(data.text!) as Map<String, dynamic>;
    final items = (json['items'] as List).map((e) {
      final m = e as Map<String, dynamic>;
      return WatchlistItem(
        symbol: m['symbol'] as String,
        name: m['name'] as String,
        addedAt: DateTime.tryParse(m['addedAt'] as String? ?? '') ??
            DateTime.now(),
      );
    }).toList();

    if (!context.mounted) return;
    final mode = await _askMergeOrReplace(context, items.length);
    if (mode == null) return;

    final notifier = ref.read(watchlistProvider.notifier);
    if (mode == _ImportMode.replace) {
      // 先移除既有
      for (final w in ref.read(watchlistProvider)) {
        notifier.remove(w.symbol);
      }
    }
    var added = 0;
    final existing =
        ref.read(watchlistProvider).map((w) => w.symbol).toSet();
    for (final item in items) {
      if (mode == _ImportMode.merge && existing.contains(item.symbol)) {
        continue;
      }
      notifier.add(item.symbol, item.name);
      added++;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('匯入完成，新增 $added 檔')),
    );
  } catch (e) {
    if (!context.mounted) return;
    _showError(context, '無法解析剪貼簿內容：$e');
  }
}

enum _ImportMode { merge, replace }

Future<_ImportMode?> _askMergeOrReplace(
    BuildContext context, int count) async {
  return showDialog<_ImportMode>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.bgCard,
      title: const Text('匯入方式'),
      content: Text('將要匯入 $count 檔自選股。請選擇處理方式：'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, _ImportMode.merge),
          child: const Text('合併（保留現有）'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, _ImportMode.replace),
          child: const Text('取代（清空現有）'),
        ),
      ],
    ),
  );
}

void _showError(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.bullish.withValues(alpha: 0.9),
    ),
  );
}
