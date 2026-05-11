import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'secure_storage_service.dart';

/// Fugle WebSocket 即時報價服務
///
/// 端點: wss://api.fugle.tw/marketdata/v1.0/stock/streaming
/// 流程: connect → auth (apikey) → authenticated → subscribe(channel, symbol)
///
/// 設計重點：
/// - 單一 WebSocket 連線多訂閱
/// - 自動重連 (指數退避，最多 5 次)
/// - Heartbeat 由伺服器主動推送，我們處理 pong 即可
/// - 各訂閱者透過 [subscribe] 拿到自己的 Stream<Map>
class FugleWebSocketService {
  FugleWebSocketService._();
  static final FugleWebSocketService instance = FugleWebSocketService._();

  static final Uri _endpoint = Uri.parse(
      'wss://api.fugle.tw/marketdata/v1.0/stock/streaming');

  WebSocketChannel? _channel;
  bool _authenticated = false;
  int _reconnectAttempt = 0;
  Timer? _reconnectTimer;
  Completer<void>? _authCompleter;

  /// 已建立的訂閱：key = "channel|symbol"
  final Map<String, _Subscription> _subscriptions = {};

  bool get isConnected => _channel != null && _authenticated;

  /// 訂閱某 channel + symbol 的即時資料
  ///
  /// 例如 `subscribe('aggregates', '2330')` 會收到聚合報價推送。
  /// 多次呼叫同 key 會共用同一個 Stream。
  Future<Stream<Map<String, dynamic>>> subscribe(
      String channel, String symbol) async {
    final key = '$channel|$symbol';
    final existing = _subscriptions[key];
    if (existing != null) {
      existing.refCount++;
      return existing.controller.stream;
    }

    await _ensureConnected();
    final controller = StreamController<Map<String, dynamic>>.broadcast();
    final sub = _Subscription(
      channel: channel,
      symbol: symbol,
      controller: controller,
      refCount: 1,
    );
    _subscriptions[key] = sub;
    _sendSubscribe(channel, symbol);
    return controller.stream;
  }

  /// 取消訂閱 (引用計數歸 0 時才真正送出 unsubscribe)
  void unsubscribe(String channel, String symbol) {
    final key = '$channel|$symbol';
    final sub = _subscriptions[key];
    if (sub == null) return;
    sub.refCount--;
    if (sub.refCount > 0) return;
    if (sub.serverId != null && _channel != null) {
      _channel!.sink.add(jsonEncode({
        'event': 'unsubscribe',
        'data': {'id': sub.serverId},
      }));
    }
    sub.controller.close();
    _subscriptions.remove(key);
    // 沒訂閱了就斷線省資源
    if (_subscriptions.isEmpty) {
      _disconnect();
    }
  }

  Future<void> _ensureConnected() async {
    if (isConnected) return;
    if (_authCompleter != null) {
      return _authCompleter!.future;
    }
    _authCompleter = Completer<void>();
    try {
      _channel = WebSocketChannel.connect(_endpoint);
      _channel!.stream.listen(
        _onMessage,
        onDone: _onDisconnect,
        onError: (_) => _onDisconnect(),
        cancelOnError: false,
      );
      // 送 auth
      final token = await SecureStorageService.instance.readToken();
      if (token == null || token.isEmpty) {
        throw StateError('尚未設定 Fugle API Token');
      }
      _channel!.sink.add(jsonEncode({
        'event': 'auth',
        'data': {'apikey': token},
      }));
      // 等待 authenticated 事件 (上限 8 秒)
      await _authCompleter!.future.timeout(const Duration(seconds: 8));
    } catch (e) {
      _authCompleter?.completeError(e);
      _authCompleter = null;
      _channel = null;
      rethrow;
    }
  }

  void _sendSubscribe(String channel, String symbol) {
    if (_channel == null) return;
    _channel!.sink.add(jsonEncode({
      'event': 'subscribe',
      'data': {'channel': channel, 'symbol': symbol},
    }));
  }

  void _onMessage(dynamic raw) {
    Map<String, dynamic> msg;
    try {
      msg = jsonDecode(raw as String) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    final event = msg['event'] as String?;
    switch (event) {
      case 'authenticated':
        _authenticated = true;
        _reconnectAttempt = 0;
        _authCompleter?.complete();
        _authCompleter = null;
        // 重連後補回所有訂閱
        for (final s in _subscriptions.values) {
          _sendSubscribe(s.channel, s.symbol);
        }
        break;
      case 'subscribed':
        final d = msg['data'];
        if (d is Map) {
          final ch = d['channel'] as String?;
          final sym = d['symbol'] as String?;
          final id = d['id']?.toString();
          if (ch != null && sym != null) {
            _subscriptions['$ch|$sym']?.serverId = id;
          }
        }
        break;
      case 'data':
        final ch = msg['channel'] as String?;
        final data = msg['data'];
        if (ch == null || data is! Map) break;
        final sym = (data['symbol'] ?? '') as String;
        final key = '$ch|$sym';
        _subscriptions[key]
            ?.controller
            .add(Map<String, dynamic>.from(data));
        break;
      case 'error':
        final d = msg['data'];
        final m = (d is Map ? d['message'] : null) ?? 'WebSocket error';
        // 把錯誤推到所有訂閱者
        for (final s in _subscriptions.values) {
          s.controller.addError(Exception(m));
        }
        break;
      case 'heartbeat':
        // 伺服器主動 heartbeat，不需要回應
        break;
    }
  }

  void _onDisconnect() {
    _authenticated = false;
    _channel = null;
    _authCompleter = null;
    // 還有訂閱者就嘗試重連
    if (_subscriptions.isEmpty) return;
    if (_reconnectAttempt >= 5) return;
    final delay = Duration(seconds: 1 << _reconnectAttempt); // 1, 2, 4, 8, 16
    _reconnectAttempt++;
    _reconnectTimer = Timer(delay, () {
      _ensureConnected().catchError((_) {});
    });
  }

  void _disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _authenticated = false;
    _reconnectAttempt = 0;
  }
}

class _Subscription {
  final String channel;
  final String symbol;
  final StreamController<Map<String, dynamic>> controller;
  int refCount;
  String? serverId;
  _Subscription({
    required this.channel,
    required this.symbol,
    required this.controller,
    required this.refCount,
    this.serverId,
  });
}
