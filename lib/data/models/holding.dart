import 'package:hive/hive.dart';

class Holding {
  final String symbol;
  final String name;
  final int quantity;        // 股數
  final double avgCost;      // 每股平均成本
  final DateTime addedAt;

  const Holding({
    required this.symbol,
    required this.name,
    required this.quantity,
    required this.avgCost,
    required this.addedAt,
  });

  double get costBasis => avgCost * quantity;

  /// 未實現損益 (基於當前價)
  double unrealizedPnL(double currentPrice) =>
      (currentPrice - avgCost) * quantity;

  /// 未實現報酬率 (%)
  double unrealizedPct(double currentPrice) {
    if (avgCost == 0) return 0;
    return (currentPrice - avgCost) / avgCost * 100;
  }

  double marketValue(double currentPrice) => currentPrice * quantity;

  Holding copyWith({
    int? quantity,
    double? avgCost,
  }) {
    return Holding(
      symbol: symbol,
      name: name,
      quantity: quantity ?? this.quantity,
      avgCost: avgCost ?? this.avgCost,
      addedAt: addedAt,
    );
  }
}

class HoldingAdapter extends TypeAdapter<Holding> {
  @override
  final int typeId = 17;

  @override
  Holding read(BinaryReader reader) {
    return Holding(
      symbol: reader.readString(),
      name: reader.readString(),
      quantity: reader.readInt32(),
      avgCost: reader.readDouble(),
      addedAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
    );
  }

  @override
  void write(BinaryWriter writer, Holding obj) {
    writer
      ..writeString(obj.symbol)
      ..writeString(obj.name)
      ..writeInt32(obj.quantity)
      ..writeDouble(obj.avgCost)
      ..writeInt(obj.addedAt.millisecondsSinceEpoch);
  }
}
