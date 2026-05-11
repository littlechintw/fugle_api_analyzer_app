import 'package:hive/hive.dart';

/// 自選股清單項目
class WatchlistItem {
  final String symbol;
  final String name;
  final DateTime addedAt;

  const WatchlistItem({
    required this.symbol,
    required this.name,
    required this.addedAt,
  });
}

class WatchlistItemAdapter extends TypeAdapter<WatchlistItem> {
  @override
  final int typeId = 13;

  @override
  WatchlistItem read(BinaryReader reader) {
    return WatchlistItem(
      symbol: reader.readString(),
      name: reader.readString(),
      addedAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
    );
  }

  @override
  void write(BinaryWriter writer, WatchlistItem obj) {
    writer
      ..writeString(obj.symbol)
      ..writeString(obj.name)
      ..writeInt(obj.addedAt.millisecondsSinceEpoch);
  }
}
