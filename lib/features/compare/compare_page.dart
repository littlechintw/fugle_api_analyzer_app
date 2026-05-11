import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_error.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/network_progress_bar.dart';
import '../../data/models/candle.dart';
import '../../data/providers/providers.dart';

class ComparePage extends ConsumerStatefulWidget {
  const ComparePage({super.key});

  @override
  ConsumerState<ComparePage> createState() => _ComparePageState();
}

class _ComparePageState extends ConsumerState<ComparePage> {
  final Set<String> _selected = {};
  static const _maxSelection = 5;
  static const _palette = [
    Color(0xFFEF476F),
    Color(0xFFFFD166),
    Color(0xFF06D6A0),
    Color(0xFF118AB2),
    Color(0xFF8E9DFF),
  ];

  @override
  Widget build(BuildContext context) {
    final watchlist = ref.watch(watchlistProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('多股對比'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(2.5),
          child: NetworkProgressBar(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(
              children: [
                Text(
                  '從自選股選 2-$_maxSelection 檔',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_selected.length} / $_maxSelection',
                  style: const TextStyle(
                    color: AppTheme.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 40,
            child: watchlist.isEmpty
                ? const Center(
                    child: Text('自選股為空，請先回首頁加入',
                        style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12)),
                  )
                : ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      for (final w in watchlist)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: Text('${w.name} ${w.symbol}',
                                style: const TextStyle(fontSize: 12)),
                            selected: _selected.contains(w.symbol),
                            onSelected: (yes) {
                              setState(() {
                                if (yes) {
                                  if (_selected.length < _maxSelection) {
                                    _selected.add(w.symbol);
                                  }
                                } else {
                                  _selected.remove(w.symbol);
                                }
                              });
                            },
                            backgroundColor: AppTheme.bgSurface,
                            selectedColor:
                                AppTheme.accent.withValues(alpha: 0.20),
                            side: BorderSide(
                              color: _selected.contains(w.symbol)
                                  ? AppTheme.accent
                                  : AppTheme.borderColor,
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
          Expanded(
            child: _selected.length < 2
                ? const Center(
                    child: Text(
                      '至少選 2 檔來比較',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  )
                : _CompareChart(symbols: _selected.toList()),
          ),
        ],
      ),
    );
  }
}

class _CompareChart extends ConsumerWidget {
  final List<String> symbols;
  const _CompareChart({required this.symbols});

  static const _palette = _ComparePageState._palette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 同步監聽全部 symbol 的 candlesProvider
    final asyncList =
        symbols.map((s) => ref.watch(candlesProvider(s))).toList();

    final allDone = asyncList.every((a) => a is AsyncData);
    if (!allDone) {
      final firstErr = asyncList.firstWhere(
        (a) => a is AsyncError,
        orElse: () => const AsyncLoading(),
      );
      if (firstErr is AsyncError) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              firstErr.error!.userMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppTheme.textPrimary, fontSize: 12),
            ),
          ),
        );
      }
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.accent),
      );
    }

    // 抓出每檔的 candles，標準化到 base = 100
    final series = <_Series>[];
    for (var i = 0; i < symbols.length; i++) {
      final c = (asyncList[i] as AsyncData<List<Candle>>).value;
      if (c.isEmpty) continue;
      final base = c.first.close;
      if (base <= 0) continue;
      series.add(_Series(
        symbol: symbols[i],
        color: _palette[i % _palette.length],
        spots: [
          for (var j = 0; j < c.length; j++)
            FlSpot(j.toDouble(), c[j].close / base * 100),
        ],
      ));
    }
    if (series.isEmpty) {
      return const Center(
        child: Text('沒有可比較的資料',
            style: TextStyle(color: AppTheme.textSecondary)),
      );
    }

    final allY = series.expand((s) => s.spots.map((p) => p.y));
    final minY = allY.reduce((a, b) => a < b ? a : b);
    final maxY = allY.reduce((a, b) => a > b ? a : b);
    final pad = (maxY - minY) * 0.08;
    final maxX = series.first.spots.length - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
      child: Column(
        children: [
          Expanded(
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: maxX.toDouble(),
                minY: minY - pad,
                maxY: maxY + pad,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxY - minY) / 4,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: AppTheme.borderColor,
                    strokeWidth: 0.5,
                    dashArray: [4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (v, _) => Text(
                        '${v.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: AppTheme.borderColor),
                ),
                extraLinesData: ExtraLinesData(horizontalLines: [
                  HorizontalLine(
                    y: 100,
                    color: AppTheme.textSecondary.withValues(alpha: 0.5),
                    strokeWidth: 0.6,
                    dashArray: [4, 4],
                    label: HorizontalLineLabel(
                      show: true,
                      labelResolver: (_) => ' 基準 100',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 10),
                    ),
                  ),
                ]),
                lineBarsData: [
                  for (final s in series)
                    LineChartBarData(
                      spots: s.spots,
                      color: s.color,
                      barWidth: 1.6,
                      isCurved: false,
                      dotData: const FlDotData(show: false),
                    ),
                ],
                lineTouchData: const LineTouchData(enabled: false),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              for (final s in series)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 14,
                      height: 2,
                      color: s.color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${s.symbol} '
                      '(${(s.spots.last.y - 100).toStringAsFixed(1)}%)',
                      style: TextStyle(
                        color: s.color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Series {
  final String symbol;
  final Color color;
  final List<FlSpot> spots;
  const _Series({
    required this.symbol,
    required this.color,
    required this.spots,
  });
}
