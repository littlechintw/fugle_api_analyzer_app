import 'package:hive/hive.dart';

/// 一檔股票的基本身份資料（來自 Fugle intraday/tickers）
class Ticker {
  final String symbol;
  final String name;
  final String exchange; // TWSE / TPEx
  final String market;   // TSE / OTC

  const Ticker({
    required this.symbol,
    required this.name,
    required this.exchange,
    required this.market,
  });

  factory Ticker.fromFugle(Map<String, dynamic> json) {
    return Ticker(
      symbol: (json['symbol'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      exchange: (json['exchange'] ?? '') as String,
      market: (json['market'] ?? '') as String,
    );
  }
}

class TickerAdapter extends TypeAdapter<Ticker> {
  @override
  final int typeId = 14;

  @override
  Ticker read(BinaryReader reader) {
    return Ticker(
      symbol: reader.readString(),
      name: reader.readString(),
      exchange: reader.readString(),
      market: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, Ticker obj) {
    writer
      ..writeString(obj.symbol)
      ..writeString(obj.name)
      ..writeString(obj.exchange)
      ..writeString(obj.market);
  }
}
