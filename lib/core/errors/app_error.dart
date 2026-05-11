import 'package:dio/dio.dart';

import '../../data/services/fugle_api_client.dart';

/// 統一錯誤類別 — UI 端永遠用 [AppError.from(e).userMessage] 拿到友善訊息
class AppError implements Exception {
  final String userMessage;
  final String? technical;
  final int? statusCode;
  final AppErrorKind kind;

  const AppError({
    required this.userMessage,
    required this.kind,
    this.technical,
    this.statusCode,
  });

  /// 把任何 Object 轉成 AppError
  factory AppError.from(Object e) {
    if (e is AppError) return e;
    if (e is DioException) return AppError._fromDio(e);
    if (e is FugleApiException) {
      return AppError(
        userMessage: e.message,
        kind: AppErrorKind.tokenMissing,
        technical: e.toString(),
      );
    }
    return AppError(
      userMessage: '發生未預期的錯誤',
      kind: AppErrorKind.unknown,
      technical: e.toString(),
    );
  }

  factory AppError._fromDio(DioException e) {
    final code = e.response?.statusCode;
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const AppError(
          userMessage: '網路連線逾時，請檢查網路後重試',
          kind: AppErrorKind.timeout,
        );
      case DioExceptionType.connectionError:
        return const AppError(
          userMessage: '無法連線到伺服器，請確認網路狀態',
          kind: AppErrorKind.network,
        );
      case DioExceptionType.cancel:
        return const AppError(
          userMessage: '請求已取消',
          kind: AppErrorKind.cancel,
        );
      case DioExceptionType.badCertificate:
        return const AppError(
          userMessage: '安全憑證驗證失敗',
          kind: AppErrorKind.network,
        );
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        break;
    }
    switch (code) {
      case 401:
        return AppError(
          userMessage: 'API Token 無效或已過期，請至設定頁面重新填寫',
          kind: AppErrorKind.tokenInvalid,
          statusCode: code,
        );
      case 403:
        return AppError(
          userMessage: '您目前的方案無法使用此功能（需開發者方案）',
          kind: AppErrorKind.forbidden,
          statusCode: code,
        );
      case 404:
        return AppError(
          userMessage: '找不到此股票或資料',
          kind: AppErrorKind.notFound,
          statusCode: code,
        );
      case 429:
        return AppError(
          userMessage: 'API 用量已達上限，請稍後再試',
          kind: AppErrorKind.rateLimited,
          statusCode: code,
        );
      case 500:
      case 502:
      case 503:
      case 504:
        return AppError(
          userMessage: 'Fugle 伺服器暫時無法回應 (HTTP $code)，請稍後再試',
          kind: AppErrorKind.serverError,
          statusCode: code,
        );
    }
    return AppError(
      userMessage: '網路或伺服器異常 ${code != null ? '(HTTP $code)' : ''}',
      kind: AppErrorKind.unknown,
      technical: e.message,
      statusCode: code,
    );
  }

  @override
  String toString() => userMessage;
}

enum AppErrorKind {
  tokenMissing,
  tokenInvalid,
  forbidden,
  notFound,
  rateLimited,
  serverError,
  timeout,
  network,
  cancel,
  unknown,
}

/// 提供 `e.userMessage` 的便利擴充
extension AppErrorMessage on Object {
  String get userMessage => AppError.from(this).userMessage;
}
