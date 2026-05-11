import 'package:flutter_riverpod/flutter_riverpod.dart';

/// K 線週期
enum ChartTimeframe { day, week, month }

extension ChartTimeframeMeta on ChartTimeframe {
  String get label => switch (this) {
        ChartTimeframe.day => '日 K',
        ChartTimeframe.week => '週 K',
        ChartTimeframe.month => '月 K',
      };
  String get apiCode => switch (this) {
        ChartTimeframe.day => 'D',
        ChartTimeframe.week => 'W',
        ChartTimeframe.month => 'M',
      };
}

/// 顯示區間
enum ChartRange { m3, m6, y1, y2, all }

extension ChartRangeMeta on ChartRange {
  String get label => switch (this) {
        ChartRange.m3 => '3 月',
        ChartRange.m6 => '6 月',
        ChartRange.y1 => '1 年',
        ChartRange.y2 => '2 年',
        ChartRange.all => '最大',
      };

  /// 在 [ChartTimeframe.day] 模式下要拉的歷史天數
  int get apiDays => switch (this) {
        ChartRange.m3 => 95,
        ChartRange.m6 => 190,
        ChartRange.y1 => 380,
        ChartRange.y2 => 760,
        ChartRange.all => 1200,
      };

  /// 顯示的 K 棒數量上限 (避免擠壓)
  int displayBarsFor(ChartTimeframe tf) {
    switch (tf) {
      case ChartTimeframe.day:
        return apiDays;
      case ChartTimeframe.week:
        return apiDays ~/ 5; // 平均 5 個交易日 = 1 週
      case ChartTimeframe.month:
        return apiDays ~/ 22;
    }
  }
}

class ChartOptions {
  final ChartTimeframe timeframe;
  final ChartRange range;
  const ChartOptions({
    this.timeframe = ChartTimeframe.day,
    this.range = ChartRange.m6,
  });

  ChartOptions copyWith({ChartTimeframe? timeframe, ChartRange? range}) {
    return ChartOptions(
      timeframe: timeframe ?? this.timeframe,
      range: range ?? this.range,
    );
  }
}

class ChartOptionsNotifier extends Notifier<ChartOptions> {
  @override
  ChartOptions build() => const ChartOptions();

  void setTimeframe(ChartTimeframe tf) {
    state = state.copyWith(timeframe: tf);
  }

  void setRange(ChartRange r) {
    state = state.copyWith(range: r);
  }
}

final chartOptionsProvider =
    NotifierProvider<ChartOptionsNotifier, ChartOptions>(
        ChartOptionsNotifier.new);
