/// 三大法人單日買賣超 (單位：張)
class InstitutionalFlow {
  final DateTime date;
  final int foreign;       // 外資+陸資
  final int trust;         // 投信
  final int dealer;        // 自營商
  const InstitutionalFlow({
    required this.date,
    required this.foreign,
    required this.trust,
    required this.dealer,
  });

  int get total => foreign + trust + dealer;
  bool get netBuy => total > 0;
}

/// 進度快照 — 給 UI 顯示「已載入 N/M 天」
class InstitutionalSnapshot {
  final List<InstitutionalFlow> flows;
  final int loaded;
  final int total;
  final bool isComplete;
  const InstitutionalSnapshot({
    required this.flows,
    required this.loaded,
    required this.total,
    required this.isComplete,
  });

  bool get isEmpty => flows.isEmpty;
  int get pending => total - loaded;
}
