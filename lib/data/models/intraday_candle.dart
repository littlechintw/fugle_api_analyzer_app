/// 當日 1 分鐘 K
class IntradayCandle {
  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
  final double? average; // 均價 (VWAP)

  const IntradayCandle({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    this.average,
  });

  factory IntradayCandle.fromFugle(Map<String, dynamic> j) {
    // Fugle 回傳 "2023-05-29T09:00:00.000+08:00" — DateTime.parse 會解析成 UTC，
    // 必須 toLocal() 才能在台灣顯示成 09:00 而不是 01:00
    return IntradayCandle(
      time: DateTime.parse(j['date'] as String).toLocal(),
      open: (j['open'] as num).toDouble(),
      high: (j['high'] as num).toDouble(),
      low: (j['low'] as num).toDouble(),
      close: (j['close'] as num).toDouble(),
      volume: (j['volume'] as num? ?? 0).toDouble(),
      average: (j['average'] as num?)?.toDouble(),
    );
  }
}
