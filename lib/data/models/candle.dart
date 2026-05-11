import 'package:hive/hive.dart';

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

class CandleListAdapter extends TypeAdapter<List<Candle>> {
  @override
  final int typeId = 10;

  @override
  List<Candle> read(BinaryReader reader) {
    final length = reader.readUint32();
    final list = <Candle>[];
    for (var i = 0; i < length; i++) {
      list.add(Candle(
        date: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
        open: reader.readDouble(),
        high: reader.readDouble(),
        low: reader.readDouble(),
        close: reader.readDouble(),
        volume: reader.readDouble(),
      ));
    }
    return list;
  }

  @override
  void write(BinaryWriter writer, List<Candle> obj) {
    writer.writeUint32(obj.length);
    for (final c in obj) {
      writer.writeInt(c.date.millisecondsSinceEpoch);
      writer.writeDouble(c.open);
      writer.writeDouble(c.high);
      writer.writeDouble(c.low);
      writer.writeDouble(c.close);
      writer.writeDouble(c.volume);
    }
  }
}
