import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_error.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/network_progress_bar.dart';
import '../../data/providers/providers.dart';
import '../../indicators/analysis.dart';
import '../alerts/price_alert_sheet.dart';
import 'widgets/diagnosis_panel.dart';
import 'widgets/indicator_chart.dart';
import 'widgets/institutional_card.dart';
import 'widgets/chart_controls.dart';
import 'widgets/data_sources_footer.dart';
import 'widgets/dividend_card.dart';
import 'widgets/fundamental_card.dart';
import 'widgets/intraday_chart.dart';
import 'widgets/kline_chart.dart';
import 'widgets/order_book_card.dart';
import 'widgets/price_header.dart';
import 'widgets/range_52w.dart';
import 'widgets/signal_card.dart';
import 'widgets/volatility_card.dart';

class StockDetailPage extends ConsumerStatefulWidget {
  final String symbol;
  final String name;
  const StockDetailPage({
    super.key,
    required this.symbol,
    required this.name,
  });

  @override
  ConsumerState<StockDetailPage> createState() => _StockDetailPageState();
}

enum DetailTab { intraday, daily }

class _StockDetailPageState extends ConsumerState<StockDetailPage> {
  int? _crosshairIndex;
  DetailTab _tab = DetailTab.daily;

  String get symbol => widget.symbol;
  String get name => widget.name;

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final quoteAsync = ref.watch(quoteProvider(symbol));
    final candlesAsync = ref.watch(candlesProvider(symbol));
    final intradayAsync = ref.watch(intradayCandlesProvider(symbol));
    final institutionalAsync = ref.watch(institutionalFlowProvider(symbol));
    final statsAsync = ref.watch(historicalStatsProvider(symbol));
    final orderBookAsync = ref.watch(orderBookProvider(symbol));
    final dividendsAsync = ref.watch(dividendsProvider(symbol));
    final fundamentalAsync = ref.watch(fundamentalProvider(symbol));
    final diagnosis = ref.watch(diagnosisProvider(symbol));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            Text(symbol,
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: '設定價格警示',
            icon: const Icon(Icons.notifications_active_outlined),
            onPressed: () {
              final q = ref.read(quoteProvider(symbol)).asData?.value;
              showPriceAlertSheet(
                context,
                symbol: symbol,
                name: name,
                currentPrice: q?.lastPrice ?? 0,
              );
            },
          ),
          Consumer(builder: (_, r, __) {
            final busy = r.watch(networkActivityProvider) > 0;
            return IconButton(
              tooltip: '重新整理',
              icon: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.accent,
                      ),
                    )
                  : const Icon(Icons.refresh),
              onPressed: busy
                  ? null
                  : () {
                      ref.invalidate(quoteProvider(symbol));
                      ref.invalidate(candlesProvider(symbol));
                    },
            );
          }),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(2.5),
          child: NetworkProgressBar(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(quoteProvider(symbol));
          ref.invalidate(candlesProvider(symbol));
          ref.invalidate(intradayCandlesProvider(symbol));
          ref.invalidate(institutionalFlowProvider(symbol));
          await Future.wait([
            ref.read(quoteProvider(symbol).future),
            ref.read(candlesProvider(symbol).future),
          ]);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            quoteAsync.when(
              data: (q) => PriceHeader(quote: q),
              loading: () => const _LoadingBlock(height: 120),
              error: (e, _) => _ErrorBlock(message: e.userMessage),
            ),
            // 52 週區間
            statsAsync.maybeWhen(
              data: (s) => Range52WCard(stats: s),
              orElse: () => const SizedBox.shrink(),
            ),
            // 五檔買賣 + 內外盤
            orderBookAsync.maybeWhen(
              data: (b) => OrderBookCard(book: b),
              orElse: () => const SizedBox.shrink(),
            ),
            // 圖表 Tab
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: SegmentedButton<DetailTab>(
                style: SegmentedButton.styleFrom(
                  backgroundColor: AppTheme.bgSurface,
                  foregroundColor: AppTheme.textSecondary,
                  selectedBackgroundColor:
                      AppTheme.accent.withValues(alpha: 0.18),
                  selectedForegroundColor: AppTheme.accent,
                  textStyle: const TextStyle(fontSize: 12),
                  side: const BorderSide(color: AppTheme.borderColor),
                ),
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                      value: DetailTab.intraday, label: Text('當日分線')),
                  ButtonSegment(
                      value: DetailTab.daily, label: Text('日 K 線')),
                ],
                selected: {_tab},
                onSelectionChanged: (s) =>
                    setState(() => _tab = s.first),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _tab == DetailTab.intraday
                  ? intradayAsync.when(
                      data: (c) {
                        final ref0 = quoteAsync.asData?.value.previousClose ?? 0;
                        return IntradayChart(
                          candles: c,
                          referencePrice: ref0,
                        );
                      },
                      loading: () => const _LoadingBlock(height: 260),
                      error: (e, _) =>
                          _ErrorBlock(message: e.toString()),
                    )
                  : candlesAsync.when(
                      data: (c) {
                        final shown = c;
                        final compare = ref.watch(compareIndexProvider);
                        final indexAsync =
                            compare ? ref.watch(indexCandlesProvider) : null;
                        return Column(
                          children: [
                            const ChartControls(),
                            const SizedBox(height: 6),
                            KLineChart(
                              candles: shown,
                              indexCandles:
                                  indexAsync?.asData?.value,
                              onHover: (i) => setState(
                                  () => _crosshairIndex = i),
                            ),
                            const SizedBox(height: 16),
                            IndicatorChart(
                              candles: shown,
                              highlightIndex: _crosshairIndex,
                            ),
                          ],
                        );
                      },
                      loading: () => const _LoadingBlock(height: 380),
                      error: (e, _) =>
                          _ErrorBlock(message: e.toString()),
                    ),
            ),
            const SizedBox(height: 8),
            // 綜合評分
            candlesAsync.maybeWhen(
              data: (c) => SignalCard(report: SignalAnalyser.analyse(c)),
              orElse: () => const SizedBox.shrink(),
            ),
            // 波動度
            candlesAsync.maybeWhen(
              data: (c) =>
                  VolatilityCard(report: VolatilityAnalyser.analyse(c)),
              orElse: () => const SizedBox.shrink(),
            ),
            // 基本面
            fundamentalAsync.maybeWhen(
              data: (f) =>
                  f == null ? const SizedBox.shrink() : FundamentalCard(snapshot: f),
              orElse: () => const SizedBox.shrink(),
            ),
            // 除權息
            dividendsAsync.maybeWhen(
              data: (list) => DividendCard(
                dividends: list,
                currentPrice:
                    quoteAsync.asData?.value.lastPrice ?? 0,
              ),
              orElse: () => const SizedBox.shrink(),
            ),
            // 三大法人
            institutionalAsync.when(
              data: (s) => InstitutionalCard(snapshot: s),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.accent),
                  ),
                ),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
            if (diagnosis.isNotEmpty) DiagnosisPanel(tags: diagnosis),
            const DataSourcesFooter(),
          ],
        ),
      ),
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  final double height;
  const _LoadingBlock({required this.height});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const Center(
        child: CircularProgressIndicator(color: AppTheme.accent),
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  final String message;
  const _ErrorBlock({required this.message});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.bullish.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppTheme.bullish, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
