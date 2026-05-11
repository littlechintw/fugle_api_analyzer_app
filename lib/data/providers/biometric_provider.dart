import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../services/hive_service.dart';

class BiometricState {
  final bool enabled;
  final bool unlocked;
  const BiometricState({required this.enabled, required this.unlocked});

  BiometricState copyWith({bool? enabled, bool? unlocked}) =>
      BiometricState(
        enabled: enabled ?? this.enabled,
        unlocked: unlocked ?? this.unlocked,
      );
}

class BiometricNotifier extends Notifier<BiometricState> {
  static const _key = 'biometric_enabled';
  final _auth = LocalAuthentication();

  @override
  BiometricState build() {
    final enabled = HiveService.instance.settings.get(_key) as bool? ?? false;
    // 預設 unlocked = !enabled (若沒啟用，永遠視為解鎖)
    return BiometricState(enabled: enabled, unlocked: !enabled);
  }

  /// 啟用前先檢查裝置是否支援
  Future<bool> canUseBiometrics() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return supported && canCheck;
    } catch (_) {
      return false;
    }
  }

  /// 設定頁打開 / 關閉
  Future<bool> setEnabled(bool v) async {
    if (v) {
      // 啟用前驗證一次，確認真的可用
      final ok = await _authenticate(
          reason: '請驗證身分以啟用生物識別解鎖');
      if (!ok) return false;
    }
    await HiveService.instance.settings.put(_key, v);
    state = state.copyWith(enabled: v, unlocked: true);
    return true;
  }

  /// 啟動時呼叫
  Future<void> unlock() async {
    if (!state.enabled) {
      state = state.copyWith(unlocked: true);
      return;
    }
    final ok = await _authenticate(reason: '解鎖股市技術分析');
    if (ok) {
      state = state.copyWith(unlocked: true);
    }
  }

  Future<bool> _authenticate({required String reason}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // 允許 PIN / 圖案 fallback
        ),
      );
    } catch (_) {
      return false;
    }
  }
}

final biometricProvider =
    NotifierProvider<BiometricNotifier, BiometricState>(
        BiometricNotifier.new);
