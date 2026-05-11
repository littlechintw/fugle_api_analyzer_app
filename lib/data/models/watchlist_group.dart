import 'package:hive/hive.dart';

/// 自選股分組 (使用者可自訂)
///
/// `__all__` 是隱式的「全部」群組，永遠存在且不可刪除，
/// 因此這個 model 只記錄使用者自訂的群組。
class WatchlistGroup {
  static const String allGroupId = '__all__';

  final String id;
  final String name;
  final int sortOrder;
  final int colorValue; // 32-bit ARGB

  const WatchlistGroup({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.colorValue,
  });

  WatchlistGroup copyWith({String? name, int? sortOrder, int? colorValue}) {
    return WatchlistGroup(
      id: id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      colorValue: colorValue ?? this.colorValue,
    );
  }
}

class WatchlistGroupAdapter extends TypeAdapter<WatchlistGroup> {
  @override
  final int typeId = 16;

  @override
  WatchlistGroup read(BinaryReader reader) {
    return WatchlistGroup(
      id: reader.readString(),
      name: reader.readString(),
      sortOrder: reader.readInt32(),
      colorValue: reader.readInt32(),
    );
  }

  @override
  void write(BinaryWriter writer, WatchlistGroup obj) {
    writer
      ..writeString(obj.id)
      ..writeString(obj.name)
      ..writeInt32(obj.sortOrder)
      ..writeInt32(obj.colorValue);
  }
}
