/// 資本變動 (減資 / 面額變更 / ETF 分割)
class CapitalChange {
  final String symbol;
  final String name;
  final DateTime? haltDate;     // 停止買賣日
  final DateTime? resumeDate;   // 恢復買賣日
  final String actionType;      // capital_reduction / par_value_change / etf_split_or_merge
  final String? reason;         // 減資原因
  final double? refundPerShare; // 每股退還
  final double? previousClose;
  final double? referencePrice;
  final String? splitType;      // 分割 / 反分割

  const CapitalChange({
    required this.symbol,
    required this.name,
    this.haltDate,
    this.resumeDate,
    required this.actionType,
    this.reason,
    this.refundPerShare,
    this.previousClose,
    this.referencePrice,
    this.splitType,
  });

  String get displayLabel => switch (actionType) {
        'capital_reduction' => '減資',
        'par_value_change' => '面額變更',
        'etf_split_or_merge' => splitType == '反分割' ? 'ETF 反分割' : 'ETF 分割',
        _ => actionType,
      };

  bool get isFuture =>
      (resumeDate ?? haltDate ?? DateTime.now()).isAfter(DateTime.now());

  factory CapitalChange.fromFugle(Map<String, dynamic> j) {
    DateTime? d(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }
    double? n(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    final raw = (j['raw'] as Map?) ?? const {};
    return CapitalChange(
      symbol: (j['symbol'] ?? '') as String,
      name: (j['name'] ?? '') as String,
      haltDate: d(j['haltDate']),
      resumeDate: d(j['resumeDate']),
      actionType: (j['actionType'] ?? '') as String,
      reason: raw['reason'] as String?,
      refundPerShare: n(raw['refundPerShare']),
      previousClose: n(raw['previousClose']),
      referencePrice: n(raw['referencePrice']),
      splitType: raw['splitType'] as String?,
    );
  }
}
