/// Fugle /historical/stats/{symbol} 回應
class HistoricalStats {
  final String symbol;
  final String name;
  final double openPrice;
  final double highPrice;
  final double lowPrice;
  final double closePrice;
  final double previousClose;
  final double week52High;
  final double week52Low;
  final double tradeVolume;
  final double tradeValue;
  final DateTime date;
  final DateTime fetchedAt;

  const HistoricalStats({
    required this.symbol,
    required this.name,
    required this.openPrice,
    required this.highPrice,
    required this.lowPrice,
    required this.closePrice,
    required this.previousClose,
    required this.week52High,
    required this.week52Low,
    required this.tradeVolume,
    required this.tradeValue,
    required this.date,
    required this.fetchedAt,
  });

  /// 距離 52 週高點百分比 (負數)，例：-3.5% 表示比高點低 3.5%
  double distanceFromHighPct() {
    if (week52High == 0) return 0;
    return (closePrice - week52High) / week52High * 100;
  }

  /// 距離 52 週低點百分比 (正數)，例：+25% 表示比低點高 25%
  double distanceFromLowPct() {
    if (week52Low == 0) return 0;
    return (closePrice - week52Low) / week52Low * 100;
  }

  /// 在 52 週區間中的相對位置 (0=低點, 1=高點)
  double rangePosition() {
    final range = week52High - week52Low;
    if (range <= 0) return 0.5;
    return ((closePrice - week52Low) / range).clamp(0, 1).toDouble();
  }

  factory HistoricalStats.fromFugle(Map<String, dynamic> j) {
    double d(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    return HistoricalStats(
      symbol: (j['symbol'] ?? '') as String,
      name: (j['name'] ?? '') as String,
      openPrice: d(j['openPrice']),
      highPrice: d(j['highPrice']),
      lowPrice: d(j['lowPrice']),
      closePrice: d(j['closePrice']),
      previousClose: d(j['previousClose']),
      week52High: d(j['week52High']),
      week52Low: d(j['week52Low']),
      tradeVolume: d(j['tradeVolume']),
      tradeValue: d(j['tradeValue']),
      date: DateTime.tryParse((j['date'] ?? '') as String) ?? DateTime.now(),
      fetchedAt: DateTime.now(),
    );
  }
}
