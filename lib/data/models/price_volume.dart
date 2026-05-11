/// 分價量表 (Fugle /intraday/volumes)
class PriceVolume {
  final double price;
  final int volume;
  final int volumeAtBid; // 內盤
  final int volumeAtAsk; // 外盤

  const PriceVolume({
    required this.price,
    required this.volume,
    required this.volumeAtBid,
    required this.volumeAtAsk,
  });

  factory PriceVolume.fromFugle(Map<String, dynamic> j) {
    int i(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }
    return PriceVolume(
      price: (j['price'] as num?)?.toDouble() ?? 0,
      volume: i(j['volume']),
      volumeAtBid: i(j['volumeAtBid']),
      volumeAtAsk: i(j['volumeAtAsk']),
    );
  }
}
