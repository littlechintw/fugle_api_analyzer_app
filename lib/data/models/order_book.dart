/// 五檔買賣盤 + 內外盤量
class OrderBookSnapshot {
  final String symbol;
  final List<PriceLevel> bids; // index 0 為最佳一檔
  final List<PriceLevel> asks;
  final int tradeVolumeAtBid; // 累計內盤量 (張)
  final int tradeVolumeAtAsk; // 累計外盤量 (張)
  final DateTime fetchedAt;

  const OrderBookSnapshot({
    required this.symbol,
    required this.bids,
    required this.asks,
    required this.tradeVolumeAtBid,
    required this.tradeVolumeAtAsk,
    required this.fetchedAt,
  });

  /// 內盤比 (0 ~ 1)
  double get bidRatio {
    final t = tradeVolumeAtBid + tradeVolumeAtAsk;
    return t == 0 ? 0.5 : tradeVolumeAtBid / t;
  }

  /// 外盤比
  double get askRatio => 1 - bidRatio;

  factory OrderBookSnapshot.fromFugleQuote(
      String symbol, Map<String, dynamic> json) {
    final bidsRaw = (json['bids'] as List?) ?? const [];
    final asksRaw = (json['asks'] as List?) ?? const [];
    final total = (json['total'] as Map?) ?? const {};

    List<PriceLevel> parse(List raw) {
      return raw.map<PriceLevel>((e) {
        final m = e as Map;
        return PriceLevel(
          price: ((m['price'] as num?) ?? 0).toDouble(),
          size: ((m['size'] as num?) ?? 0).toInt(),
        );
      }).toList();
    }

    return OrderBookSnapshot(
      symbol: symbol,
      bids: parse(bidsRaw),
      asks: parse(asksRaw),
      tradeVolumeAtBid: ((total['tradeVolumeAtBid'] as num?) ?? 0).toInt(),
      tradeVolumeAtAsk: ((total['tradeVolumeAtAsk'] as num?) ?? 0).toInt(),
      fetchedAt: DateTime.now(),
    );
  }
}

class PriceLevel {
  final double price;
  final int size; // 張數
  const PriceLevel({required this.price, required this.size});
}
