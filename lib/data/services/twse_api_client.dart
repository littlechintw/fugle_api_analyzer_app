import 'dart:async';

import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../models/institutional_flow.dart';
import 'hive_service.dart';

/// TWSE 公開 API — 三大法人買賣超 (上市)
///
/// 效能設計：
///   1. **整日資料快取**：呼叫 T86 端點時，TWSE 已經回傳「當日全市場 1500+ 檔」資料。
///      我們會把整天份的資料以 `{symbol: [foreign, trust, dealer]}` 存到 Hive，
///      key = `instflow_day_{yyyyMMdd}`。下次查任一檔同日資料時直接命中快取。
///   2. **並行請求**：要拉 N 個工作日時，用 Future.wait 同時發出。
///   3. **歷史不變性**：超過今天 1 日以前的資料才寫入快取，避免快取尚未公告的今天/盤中資料。
///
/// 端點 /rwd/zh/fund/T86：
///   { stat: 'OK', data: [[代號, 名稱, 外資買, 外資賣, 外資買賣超, ...], ...] }
class TwseApiClient {
  static const String _baseUrl = 'https://www.twse.com.tw';
  static const String _emptyMarker = '__EMPTY__';

  final Dio _dio;
  final HiveService _hive;

  TwseApiClient._(this._dio, this._hive);

  factory TwseApiClient.create({HiveService? hive}) {
    final dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Accept': 'application/json'},
    ));
    return TwseApiClient._(dio, hive ?? HiveService.instance);
  }

  static final _dateFmt = DateFormat('yyyyMMdd');

  /// 取得某日某股票的三大法人買賣超。
  /// 內含整日資料快取邏輯：第一次抓會把該日全市場資料整批快取。
  Future<InstitutionalFlow?> dailyInstitutional({
    required DateTime date,
    required String symbol,
  }) async {
    final dateKey = 'instflow_day_${_dateFmt.format(date)}';

    // 1. 嘗試從快取讀
    final cached = _hive.settings.get(dateKey);
    if (cached == _emptyMarker) return null;
    if (cached is Map) {
      final row = cached[symbol];
      if (row is List && row.length >= 3) {
        return InstitutionalFlow(
          date: date,
          foreign: (row[0] as num).toInt(),
          trust: (row[1] as num).toInt(),
          dealer: (row[2] as num).toInt(),
        );
      }
      return null; // 該日有資料但無此檔 (例如剛上市或下市)
    }

    // 2. 快取沒有 → 打 API
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        '/rwd/zh/fund/T86',
        queryParameters: {
          'date': _dateFmt.format(date),
          'selectType': 'ALL',
          'response': 'json',
        },
      );
      final data = resp.data;
      final isHistorical = DateTime.now().difference(date).inDays > 1;

      if (data == null || data['stat'] != 'OK') {
        // 該日無資料 (假日或尚未公告)，僅在「歷史日期」時寫入 EMPTY 標記
        if (isHistorical) {
          await _hive.settings.put(dateKey, _emptyMarker);
        }
        return null;
      }

      final rows = (data['data'] as List?) ?? const [];
      final allFlows = <String, List<int>>{};
      for (final r in rows) {
        if (r is! List || r.isEmpty) continue;
        final code = r[0].toString().trim();
        int parse(int idx) {
          if (idx >= r.length) return 0;
          final v = r[idx].toString().replaceAll(',', '');
          return int.tryParse(v) ?? 0;
        }
        // 欄位順序 (TWSE T86)：
        // 0:代號 1:名稱
        // 2-4: 外資不含自營商 (買/賣/買賣超)
        // 5-7: 外資自營商 (買/賣/買賣超)
        // 8-10: 投信 (買/賣/買賣超)
        // 11-13: 自營商-自行買賣 (買/賣/買賣超)
        // 14-16: 自營商-避險 (買/賣/買賣超)
        // 17: 自營商買賣超合計
        // 18: 三大法人買賣超合計
        final foreign = parse(4) ~/ 1000;
        final trust = parse(10) ~/ 1000;
        final dealer = (parse(11) + parse(12) + parse(13) + parse(14)) ~/ 1000;
        allFlows[code] = [foreign, trust, dealer];
      }

      // 3. 寫入整日快取 — 拿到實際資料就快取 (TWSE 歷史資料不會變)
      if (allFlows.isNotEmpty) {
        await _hive.settings.put(dateKey, allFlows);
      }

      final row = allFlows[symbol];
      if (row == null) return null;
      return InstitutionalFlow(
        date: date,
        foreign: row[0],
        trust: row[1],
        dealer: row[2],
      );
    } catch (_) {
      return null;
    }
  }

  /// 抓近 [days] 個交易日的三大法人 — 一次性回傳 (Future)
  Future<List<InstitutionalFlow>> recentFlows(
    String symbol, {
    int days = 5,
  }) async {
    final dates = _recentBusinessDays(days);
    final futures = dates.map(
      (d) => dailyInstitutional(date: d, symbol: symbol),
    );
    final results = await Future.wait(futures);
    final out = results.whereType<InstitutionalFlow>().toList();
    out.sort((a, b) => a.date.compareTo(b.date));
    return out;
  }

  /// 漸進式抓近 [days] 個交易日的三大法人，吐含進度的快照
  ///
  /// 設計重點：
  /// 1. 實際抓 `days + 1` 天做緩衝：今天若尚未公告 (約 17:00 前)，
  ///    最舊的一天會自動補上，UI 仍能看到 [days] 筆。
  /// 2. 快取命中的日期立刻計入並 yield 第一個快照。
  /// 3. 沒命中的日期用 worker pool 控制並行數 (預設 2 條)。
  Stream<InstitutionalSnapshot> recentFlowsSnapshotStream(
    String symbol, {
    int days = 5,
    int maxConcurrency = 2,
  }) async* {
    final fetchDays = days + 1; // 多抓一天緩衝
    final dates = _recentBusinessDays(fetchDays);
    final fromCache = <InstitutionalFlow>[];
    final toFetch = <DateTime>[];
    var resolvedFromCache = 0;

    for (final d in dates) {
      final dateKey = 'instflow_day_${_dateFmt.format(d)}';
      final cached = _hive.settings.get(dateKey);
      if (cached == _emptyMarker) {
        resolvedFromCache++;
        continue;
      }
      if (cached is Map) {
        resolvedFromCache++;
        final row = cached[symbol];
        if (row is List && row.length >= 3) {
          fromCache.add(InstitutionalFlow(
            date: d,
            foreign: (row[0] as num).toInt(),
            trust: (row[1] as num).toInt(),
            dealer: (row[2] as num).toInt(),
          ));
        }
        continue;
      }
      toFetch.add(d);
    }

    final accumulated = [...fromCache];

    // 顯示用：取最新 [days] 筆 (依日期升冪)
    List<InstitutionalFlow> visible() {
      accumulated.sort((a, b) => a.date.compareTo(b.date));
      return accumulated.length > days
          ? accumulated.sublist(accumulated.length - days)
          : List.of(accumulated);
    }

    yield InstitutionalSnapshot(
      flows: List.unmodifiable(visible()),
      loaded: resolvedFromCache,
      total: fetchDays,
      isComplete: toFetch.isEmpty,
    );
    if (toFetch.isEmpty) return;

    final queue = List<DateTime>.from(toFetch);
    final controller = StreamController<InstitutionalFlow?>();

    Future<void> worker() async {
      while (queue.isNotEmpty) {
        final d = queue.removeAt(0);
        final r = await dailyInstitutional(date: d, symbol: symbol);
        if (!controller.isClosed) controller.add(r);
      }
    }

    final workers = List.generate(
      maxConcurrency.clamp(1, toFetch.length),
      (_) => worker(),
    );
    unawaited(Future.wait(workers).whenComplete(controller.close));

    var loaded = resolvedFromCache;
    await for (final r in controller.stream) {
      loaded++;
      if (r != null) accumulated.add(r);
      yield InstitutionalSnapshot(
        flows: List.unmodifiable(visible()),
        loaded: loaded,
        total: fetchDays,
        isComplete: loaded >= fetchDays,
      );
    }
  }

  /// 從今天往回取 [days] 個工作日 (跳過週末)
  List<DateTime> _recentBusinessDays(int days) {
    final out = <DateTime>[];
    var cursor = DateTime.now();
    while (out.length < days) {
      if (cursor.weekday != DateTime.saturday &&
          cursor.weekday != DateTime.sunday) {
        out.add(DateTime(cursor.year, cursor.month, cursor.day));
      }
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return out;
  }
}
