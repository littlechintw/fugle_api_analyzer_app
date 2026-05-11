/// 市場熱度排行單筆 (來自 snapshot/movers / snapshot/actives)
class MarketMover {
  final String symbol;
  final String name;
  final double openPrice;
  final double highPrice;
  final double lowPrice;
  final double closePrice;
  final double change;
  final double changePercent;
  final double tradeVolume; // 張
  final double tradeValue;  // 元

  const MarketMover({
    required this.symbol,
    required this.name,
    required this.openPrice,
    required this.highPrice,
    required this.lowPrice,
    required this.closePrice,
    required this.change,
    required this.changePercent,
    required this.tradeVolume,
    required this.tradeValue,
  });

  factory MarketMover.fromFugle(Map<String, dynamic> j) {
    double d(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    return MarketMover(
      symbol: (j['symbol'] ?? '') as String,
      name: (j['name'] ?? '') as String,
      openPrice: d(j['openPrice']),
      highPrice: d(j['highPrice']),
      lowPrice: d(j['lowPrice']),
      closePrice: d(j['closePrice']),
      change: d(j['change']),
      changePercent: d(j['changePercent']),
      tradeVolume: d(j['tradeVolume']),
      tradeValue: d(j['tradeValue']),
    );
  }
}
