import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/hive_service.dart';

/// 使用者自訂的指標參數
class IndicatorPrefs {
  final List<int> maPeriods;     // 預設 [5, 10, 20, 60]
  final int rsiPeriod;           // 14
  final int kdPeriod;            // 9
  final int macdFast;            // 12
  final int macdSlow;            // 26
  final int macdSignal;          // 9
  final int bollingerPeriod;     // 20
  final double bollingerStdDev;  // 2.0
  final int biasPeriod;          // 20
  final int williamsPeriod;      // 14
  final int atrPeriod;           // 14

  const IndicatorPrefs({
    this.maPeriods = const [5, 10, 20, 60],
    this.rsiPeriod = 14,
    this.kdPeriod = 9,
    this.macdFast = 12,
    this.macdSlow = 26,
    this.macdSignal = 9,
    this.bollingerPeriod = 20,
    this.bollingerStdDev = 2.0,
    this.biasPeriod = 20,
    this.williamsPeriod = 14,
    this.atrPeriod = 14,
  });

  IndicatorPrefs copyWith({
    List<int>? maPeriods,
    int? rsiPeriod,
    int? kdPeriod,
    int? macdFast,
    int? macdSlow,
    int? macdSignal,
    int? bollingerPeriod,
    double? bollingerStdDev,
    int? biasPeriod,
    int? williamsPeriod,
    int? atrPeriod,
  }) {
    return IndicatorPrefs(
      maPeriods: maPeriods ?? this.maPeriods,
      rsiPeriod: rsiPeriod ?? this.rsiPeriod,
      kdPeriod: kdPeriod ?? this.kdPeriod,
      macdFast: macdFast ?? this.macdFast,
      macdSlow: macdSlow ?? this.macdSlow,
      macdSignal: macdSignal ?? this.macdSignal,
      bollingerPeriod: bollingerPeriod ?? this.bollingerPeriod,
      bollingerStdDev: bollingerStdDev ?? this.bollingerStdDev,
      biasPeriod: biasPeriod ?? this.biasPeriod,
      williamsPeriod: williamsPeriod ?? this.williamsPeriod,
      atrPeriod: atrPeriod ?? this.atrPeriod,
    );
  }

  Map<String, dynamic> toMap() => {
        'ma': maPeriods,
        'rsi': rsiPeriod,
        'kd': kdPeriod,
        'mFast': macdFast,
        'mSlow': macdSlow,
        'mSig': macdSignal,
        'bb': bollingerPeriod,
        'bbSd': bollingerStdDev,
        'bias': biasPeriod,
        'wr': williamsPeriod,
        'atr': atrPeriod,
      };

  factory IndicatorPrefs.fromMap(Map m) => IndicatorPrefs(
        maPeriods: (m['ma'] as List?)?.cast<int>() ?? const [5, 10, 20, 60],
        rsiPeriod: (m['rsi'] as num?)?.toInt() ?? 14,
        kdPeriod: (m['kd'] as num?)?.toInt() ?? 9,
        macdFast: (m['mFast'] as num?)?.toInt() ?? 12,
        macdSlow: (m['mSlow'] as num?)?.toInt() ?? 26,
        macdSignal: (m['mSig'] as num?)?.toInt() ?? 9,
        bollingerPeriod: (m['bb'] as num?)?.toInt() ?? 20,
        bollingerStdDev: (m['bbSd'] as num?)?.toDouble() ?? 2.0,
        biasPeriod: (m['bias'] as num?)?.toInt() ?? 20,
        williamsPeriod: (m['wr'] as num?)?.toInt() ?? 14,
        atrPeriod: (m['atr'] as num?)?.toInt() ?? 14,
      );
}

class IndicatorPrefsNotifier extends Notifier<IndicatorPrefs> {
  static const _key = 'indicator_prefs';

  @override
  IndicatorPrefs build() {
    final raw = HiveService.instance.settings.get(_key);
    if (raw is Map) {
      try {
        return IndicatorPrefs.fromMap(raw);
      } catch (_) {
        return const IndicatorPrefs();
      }
    }
    return const IndicatorPrefs();
  }

  void update(IndicatorPrefs p) {
    state = p;
    HiveService.instance.settings.put(_key, p.toMap());
  }

  void reset() => update(const IndicatorPrefs());
}

final indicatorPrefsProvider =
    NotifierProvider<IndicatorPrefsNotifier, IndicatorPrefs>(
        IndicatorPrefsNotifier.new);
