/// 除權息資料 (Fugle /corporate-actions/dividends)
class Dividend {
  final DateTime date;          // 除權息日 (未來則為預告日)
  final String symbol;
  final String name;
  final double dividend;        // 權息合計
  final double cashDividend;    // 現金股利
  final double stockDividendShares; // 每仟股配股 (股)
  final String dividendType;    // 息 / 權 / 權息
  final double? referencePrice; // 除權息參考價 (除息後)
  final double? previousClose;  // 除權息前收盤

  const Dividend({
    required this.date,
    required this.symbol,
    required this.name,
    required this.dividend,
    required this.cashDividend,
    required this.stockDividendShares,
    required this.dividendType,
    this.referencePrice,
    this.previousClose,
  });

  bool get isFuture => date.isAfter(DateTime.now());

  /// 用「除權息前收盤價」估的現金殖利率 %
  double? get cashYield {
    if (previousClose == null || previousClose! <= 0) return null;
    return cashDividend / previousClose! * 100;
  }

  factory Dividend.fromFugle(Map<String, dynamic> j) {
    double? num0(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    double dD(dynamic v) => num0(v) ?? 0;

    return Dividend(
      date: DateTime.parse(j['date'] as String),
      symbol: (j['symbol'] ?? '') as String,
      name: (j['name'] ?? '') as String,
      dividend: dD(j['dividend']),
      cashDividend: dD(j['cashDividend']),
      stockDividendShares: dD(j['stockDividendShares']),
      dividendType: (j['dividendType'] ?? '') as String,
      referencePrice: num0(j['referencePrice']),
      previousClose: num0(j['previousClose']),
    );
  }
}
