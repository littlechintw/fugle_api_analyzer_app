/// 日 K 蠟燭資料 (OHLCV)
class Candle {
  final DateTime date;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  const Candle({
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  bool get isBullish => close >= open;

  Map<String, dynamic> toMap() => {
        'date': date.toIso8601String(),
        'open': open,
        'high': high,
        'low': low,
        'close': close,
        'volume': volume,
      };

  factory Candle.fromMap(Map<String, dynamic> m) => Candle(
        date: DateTime.parse(m['date'] as String),
        open: (m['open'] as num).toDouble(),
        high: (m['high'] as num).toDouble(),
        low: (m['low'] as num).toDouble(),
        close: (m['close'] as num).toDouble(),
        volume: (m['volume'] as num).toDouble(),
      );

  /// 解析 Fugle historical candles 回應的單筆 candle
  factory Candle.fromFugleHistorical(Map<String, dynamic> json) {
    return Candle(
      date: DateTime.parse(json['date'] as String),
      open: (json['open'] as num).toDouble(),
      high: (json['high'] as num).toDouble(),
      low: (json['low'] as num).toDouble(),
      close: (json['close'] as num).toDouble(),
      volume: (json['volume'] as num).toDouble(),
    );
  }
}

