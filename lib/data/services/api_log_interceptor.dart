import 'package:dio/dio.dart';

import '../models/api_log.dart';
import 'hive_service.dart';

/// Dio Interceptor —
/// 1. 紀錄每一次 API 呼叫至 Hive，供設定頁統計顯示。
/// 2. 透過 [onRequestStart] / [onRequestEnd] 回報 in-flight 狀態，
///    讓 UI 顯示載入條。
class ApiLogInterceptor extends Interceptor {
  final HiveService _hive;
  final void Function()? onRequestStart;
  final void Function()? onRequestEnd;

  ApiLogInterceptor(
    this._hive, {
    this.onRequestStart,
    this.onRequestEnd,
  });

  // 用 RequestOptions extra 傳遞起始時間
  static const _startKey = '_api_log_start_ms';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startKey] = DateTime.now().millisecondsSinceEpoch;
    onRequestStart?.call();
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _writeLog(
      response.requestOptions,
      statusCode: response.statusCode,
      success: true,
    );
    onRequestEnd?.call();
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _writeLog(
      err.requestOptions,
      statusCode: err.response?.statusCode,
      success: false,
    );
    onRequestEnd?.call();
    handler.next(err);
  }

  void _writeLog(
    RequestOptions options, {
    required int? statusCode,
    required bool success,
  }) {
    try {
      final start = options.extra[_startKey] as int?;
      final duration = start == null
          ? 0
          : DateTime.now().millisecondsSinceEpoch - start;
      _hive.apiLogs.add(ApiLog(
        timestamp: DateTime.now(),
        method: options.method,
        path: options.path,
        statusCode: statusCode,
        durationMs: duration,
        success: success,
      ));
    } catch (_) {
      // 紀錄失敗不應中斷主流程
    }
  }
}
