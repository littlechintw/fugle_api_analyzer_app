import 'package:hive/hive.dart';

/// 單筆 API 呼叫紀錄
class ApiLog {
  final DateTime timestamp;
  final String method;
  final String path;
  final int? statusCode;
  final int durationMs;
  final bool success;

  const ApiLog({
    required this.timestamp,
    required this.method,
    required this.path,
    required this.statusCode,
    required this.durationMs,
    required this.success,
  });

  /// 該紀錄是否屬於「今日」(以裝置本地時區為準)
  bool isToday(DateTime now) {
    return timestamp.year == now.year &&
        timestamp.month == now.month &&
        timestamp.day == now.day;
  }

  bool isWithinDays(int days, DateTime now) {
    final cutoff = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days - 1));
    return !timestamp.isBefore(cutoff);
  }
}

class ApiLogAdapter extends TypeAdapter<ApiLog> {
  @override
  final int typeId = 12;

  @override
  ApiLog read(BinaryReader reader) {
    return ApiLog(
      timestamp: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      method: reader.readString(),
      path: reader.readString(),
      statusCode: reader.readBool() ? reader.readInt32() : null,
      durationMs: reader.readInt32(),
      success: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, ApiLog obj) {
    writer
      ..writeInt(obj.timestamp.millisecondsSinceEpoch)
      ..writeString(obj.method)
      ..writeString(obj.path)
      ..writeBool(obj.statusCode != null);
    if (obj.statusCode != null) writer.writeInt32(obj.statusCode!);
    writer
      ..writeInt32(obj.durationMs)
      ..writeBool(obj.success);
  }
}
