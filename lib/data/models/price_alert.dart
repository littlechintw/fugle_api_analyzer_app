import 'package:hive/hive.dart';

enum AlertDirection { above, below }

class PriceAlert {
  final String id;          // symbol + direction + price (作為唯一鍵)
  final String symbol;
  final String name;
  final AlertDirection direction;
  final double price;
  final DateTime createdAt;
  final DateTime? lastTriggeredAt;
  final bool enabled;

  const PriceAlert({
    required this.id,
    required this.symbol,
    required this.name,
    required this.direction,
    required this.price,
    required this.createdAt,
    this.lastTriggeredAt,
    this.enabled = true,
  });

  PriceAlert copyWith({
    bool? enabled,
    DateTime? lastTriggeredAt,
  }) {
    return PriceAlert(
      id: id,
      symbol: symbol,
      name: name,
      direction: direction,
      price: price,
      createdAt: createdAt,
      lastTriggeredAt: lastTriggeredAt ?? this.lastTriggeredAt,
      enabled: enabled ?? this.enabled,
    );
  }

  /// 判斷當前價是否觸發警示
  bool isTriggered(double currentPrice) {
    if (!enabled) return false;
    return direction == AlertDirection.above
        ? currentPrice >= price
        : currentPrice <= price;
  }

  String get directionLabel =>
      direction == AlertDirection.above ? '高於' : '低於';

  static String makeId(String symbol, AlertDirection d, double price) =>
      '$symbol-${d.name}-${price.toStringAsFixed(4)}';
}

class PriceAlertAdapter extends TypeAdapter<PriceAlert> {
  @override
  final int typeId = 15;

  @override
  PriceAlert read(BinaryReader reader) {
    return PriceAlert(
      id: reader.readString(),
      symbol: reader.readString(),
      name: reader.readString(),
      direction: AlertDirection.values[reader.readInt32()],
      price: reader.readDouble(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      lastTriggeredAt: reader.readBool()
          ? DateTime.fromMillisecondsSinceEpoch(reader.readInt())
          : null,
      enabled: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, PriceAlert obj) {
    writer
      ..writeString(obj.id)
      ..writeString(obj.symbol)
      ..writeString(obj.name)
      ..writeInt32(obj.direction.index)
      ..writeDouble(obj.price)
      ..writeInt(obj.createdAt.millisecondsSinceEpoch)
      ..writeBool(obj.lastTriggeredAt != null);
    if (obj.lastTriggeredAt != null) {
      writer.writeInt(obj.lastTriggeredAt!.millisecondsSinceEpoch);
    }
    writer.writeBool(obj.enabled);
  }
}
