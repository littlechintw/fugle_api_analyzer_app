/// 基本面快照 (TWSE BWIBBU_d 每日本益比、殖利率、股價淨值比)
class FundamentalSnapshot {
  final String symbol;
  final double? peRatio;        // 本益比
  final double? pbRatio;        // 股價淨值比
  final double? dividendYield;  // 殖利率 (%)
  final String? dividendYear;   // 股利所屬年度
  final DateTime fetchedAt;

  const FundamentalSnapshot({
    required this.symbol,
    this.peRatio,
    this.pbRatio,
    this.dividendYield,
    this.dividendYear,
    required this.fetchedAt,
  });

  factory FundamentalSnapshot.fromTwse(
      String symbol, Map<String, dynamic> row) {
    double? d(dynamic v) {
      if (v == null) return null;
      final s = v.toString().replaceAll(',', '').trim();
      if (s.isEmpty || s == '-') return null;
      return double.tryParse(s);
    }

    return FundamentalSnapshot(
      symbol: symbol,
      peRatio: d(row['本益比'] ?? row['PEratio']),
      pbRatio: d(row['股價淨值比'] ?? row['PBratio']),
      dividendYield: d(row['殖利率(%)'] ?? row['DividendYield']),
      dividendYear: (row['股利年度'] ?? row['FinancialReportYear'])?.toString(),
      fetchedAt: DateTime.now(),
    );
  }

  bool get isEmpty => peRatio == null && pbRatio == null && dividendYield == null;
}
