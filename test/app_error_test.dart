import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fugle_api_app/core/errors/app_error.dart';
import 'package:fugle_api_app/data/services/fugle_api_client.dart';

DioException _dio({DioExceptionType? type, int? status}) {
  final req = RequestOptions(path: '/test');
  return DioException(
    requestOptions: req,
    type: type ?? DioExceptionType.unknown,
    response: status == null
        ? null
        : Response(
            requestOptions: req,
            statusCode: status,
          ),
  );
}

void main() {
  group('AppError.from', () {
    test('已是 AppError 直接回傳同一物件', () {
      const e = AppError(
        userMessage: 'X',
        kind: AppErrorKind.unknown,
      );
      expect(AppError.from(e), same(e));
    });

    test('FugleApiException → tokenMissing', () {
      final e = AppError.from(const FugleApiException('Token 沒設'));
      expect(e.kind, AppErrorKind.tokenMissing);
      expect(e.userMessage, contains('Token'));
    });

    test('未知 Object → unknown', () {
      final e = AppError.from(StateError('boom'));
      expect(e.kind, AppErrorKind.unknown);
      expect(e.userMessage, '發生未預期的錯誤');
    });
  });

  group('AppError._fromDio (HTTP status)', () {
    test('401 → tokenInvalid', () {
      final e = AppError.from(_dio(status: 401));
      expect(e.kind, AppErrorKind.tokenInvalid);
      expect(e.statusCode, 401);
      expect(e.userMessage, contains('Token'));
    });

    test('403 → forbidden', () {
      final e = AppError.from(_dio(status: 403));
      expect(e.kind, AppErrorKind.forbidden);
    });

    test('404 → notFound', () {
      final e = AppError.from(_dio(status: 404));
      expect(e.kind, AppErrorKind.notFound);
    });

    test('429 → rateLimited', () {
      final e = AppError.from(_dio(status: 429));
      expect(e.kind, AppErrorKind.rateLimited);
    });

    test('500 系列 → serverError', () {
      for (final s in [500, 502, 503, 504]) {
        final e = AppError.from(_dio(status: s));
        expect(e.kind, AppErrorKind.serverError);
        expect(e.userMessage, contains('$s'));
      }
    });
  });

  group('AppError._fromDio (連線類)', () {
    test('connectionTimeout → timeout', () {
      final e = AppError.from(_dio(type: DioExceptionType.connectionTimeout));
      expect(e.kind, AppErrorKind.timeout);
    });

    test('connectionError → network', () {
      final e = AppError.from(_dio(type: DioExceptionType.connectionError));
      expect(e.kind, AppErrorKind.network);
    });

    test('cancel → cancel', () {
      final e = AppError.from(_dio(type: DioExceptionType.cancel));
      expect(e.kind, AppErrorKind.cancel);
    });
  });

  group('userMessage extension', () {
    test('Object.userMessage 等同 AppError.from(this).userMessage', () {
      final ex = StateError('x');
      expect(ex.userMessage, AppError.from(ex).userMessage);
    });
  });

  group('toString', () {
    test('toString = userMessage', () {
      const e = AppError(
        userMessage: '錯誤訊息',
        kind: AppErrorKind.unknown,
      );
      expect(e.toString(), '錯誤訊息');
    });
  });
}
