import 'package:hive/hive.dart';

/// 盤中即時報價快照
class StockQuote {
  final String symbol;
  final String name;
  final double lastPrice;
  final double change;
  final double changePercent;
  final double openPrice;
  final double highPrice;
  final double lowPrice;
  final double previousClose;
  final double volume;
  final DateTime updatedAt;

  const StockQuote({
    required this.symbol,
    required this.name,
    required this.lastPrice,
    required this.change,
    required this.changePercent,
    required this.openPrice,
    required this.highPrice,
    required this.lowPrice,
    required this.previousClose,
    required this.volume,
    required this.updatedAt,
  });

  /// 從 Fugle intraday/quote 回應建構
  factory StockQuote.fromFugleQuote(Map<String, dynamic> json) {
    final symbol = (json['symbol'] ?? json['symbolId'] ?? '') as String;
    final name = (json['name'] ?? '') as String;
    final last = _toDouble(json['lastPrice'] ?? json['closePrice']);
    final prev = _toDouble(json['previousClose'] ?? json['referencePrice']);
    final change = _toDouble(json['change']) == 0 && prev != 0
        ? last - prev
        : _toDouble(json['change']);
    final changePct = _toDouble(json['changePercent']) == 0 && prev != 0
        ? (last - prev) / prev * 100
        : _toDouble(json['changePercent']);

    return StockQuote(
      symbol: symbol,
      name: name,
      lastPrice: last,
      change: change,
      changePercent: changePct,
      openPrice: _toDouble(json['openPrice']),
      highPrice: _toDouble(json['highPrice']),
      lowPrice: _toDouble(json['lowPrice']),
      previousClose: prev,
      volume: _toDouble(json['total']?['tradeVolume'] ?? json['volume']),
      updatedAt: DateTime.now(),
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

class StockQuoteAdapter extends TypeAdapter<StockQuote> {
  @override
  final int typeId = 11;

  @override
  StockQuote read(BinaryReader reader) {
    return StockQuote(
      symbol: reader.readString(),
      name: reader.readString(),
      lastPrice: reader.readDouble(),
      change: reader.readDouble(),
      changePercent: reader.readDouble(),
      openPrice: reader.readDouble(),
      highPrice: reader.readDouble(),
      lowPrice: reader.readDouble(),
      previousClose: reader.readDouble(),
      volume: reader.readDouble(),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
    );
  }

  @override
  void write(BinaryWriter writer, StockQuote obj) {
    writer
      ..writeString(obj.symbol)
      ..writeString(obj.name)
      ..writeDouble(obj.lastPrice)
      ..writeDouble(obj.change)
      ..writeDouble(obj.changePercent)
      ..writeDouble(obj.openPrice)
      ..writeDouble(obj.highPrice)
      ..writeDouble(obj.lowPrice)
      ..writeDouble(obj.previousClose)
      ..writeDouble(obj.volume)
      ..writeInt(obj.updatedAt.millisecondsSinceEpoch);
  }
}
