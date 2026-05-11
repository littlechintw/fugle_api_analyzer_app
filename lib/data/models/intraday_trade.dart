/// 一筆逐筆成交 (Fugle /intraday/trades)
class IntradayTrade {
  final DateTime time;
  final double? bid;
  final double? ask;
  final double price;
  final int size;       // 單筆成交量 (整股單位：張；零股：股)
  final int? volume;    // 累計成交總量
  final int serial;

  const IntradayTrade({
    required this.time,
    this.bid,
    this.ask,
    required this.price,
    required this.size,
    this.volume,
    required this.serial,
  });

  /// 主動買 (價格成交在 ask)
  bool get isBuy => ask != null && price >= ask!;

  /// 主動賣 (價格成交在 bid)
  bool get isSell => bid != null && price <= bid!;

  factory IntradayTrade.fromFugle(Map<String, dynamic> j) {
    double? n(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }
    int? i(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }
    // time 是 microseconds since epoch
    final t = i(j['time']) ?? 0;
    return IntradayTrade(
      time: DateTime.fromMicrosecondsSinceEpoch(t).toLocal(),
      bid: n(j['bid']),
      ask: n(j['ask']),
      price: n(j['price']) ?? 0,
      size: i(j['size']) ?? 0,
      volume: i(j['volume']),
      serial: i(j['serial']) ?? 0,
    );
  }
}
