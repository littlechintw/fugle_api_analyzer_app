import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/providers/indicator_prefs_provider.dart';

class IndicatorSettingsPage extends ConsumerStatefulWidget {
  const IndicatorSettingsPage({super.key});

  @override
  ConsumerState<IndicatorSettingsPage> createState() =>
      _IndicatorSettingsPageState();
}

class _IndicatorSettingsPageState
    extends ConsumerState<IndicatorSettingsPage> {
  late IndicatorPrefs _draft;
  final _ma1 = TextEditingController();
  final _ma2 = TextEditingController();
  final _ma3 = TextEditingController();
  final _ma4 = TextEditingController();

  @override
  void initState() {
    super.initState();
    _draft = ref.read(indicatorPrefsProvider);
    final ma = _draft.maPeriods;
    _ma1.text = (ma.elementAtOrNull(0) ?? 5).toString();
    _ma2.text = (ma.elementAtOrNull(1) ?? 10).toString();
    _ma3.text = (ma.elementAtOrNull(2) ?? 20).toString();
    _ma4.text = (ma.elementAtOrNull(3) ?? 60).toString();
  }

  @override
  void dispose() {
    _ma1.dispose();
    _ma2.dispose();
    _ma3.dispose();
    _ma4.dispose();
    super.dispose();
  }

  void _save() {
    final ma = [_ma1, _ma2, _ma3, _ma4]
        .map((c) => int.tryParse(c.text))
        .whereType<int>()
        .where((v) => v > 0 && v <= 500)
        .toList();
    if (ma.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('至少 2 條 MA 週期')),
      );
      return;
    }
    final p = _draft.copyWith(maPeriods: ma);
    ref.read(indicatorPrefsProvider.notifier).update(p);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('指標參數'),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(indicatorPrefsProvider.notifier).reset();
              Navigator.pop(context);
            },
            child: const Text('重置預設'),
          ),
          TextButton(
            onPressed: _save,
            child: const Text('儲存'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('移動平均 MA (最多 4 條)'),
          Row(
            children: [
              Expanded(child: _intField('MA1', _ma1)),
              const SizedBox(width: 8),
              Expanded(child: _intField('MA2', _ma2)),
              const SizedBox(width: 8),
              Expanded(child: _intField('MA3', _ma3)),
              const SizedBox(width: 8),
              Expanded(child: _intField('MA4', _ma4)),
            ],
          ),
          const SizedBox(height: 20),
          _section('震盪指標'),
          _slider(
            label: 'RSI 週期',
            value: _draft.rsiPeriod.toDouble(),
            min: 2,
            max: 30,
            divisions: 28,
            onChanged: (v) =>
                setState(() => _draft = _draft.copyWith(rsiPeriod: v.toInt())),
          ),
          _slider(
            label: 'KD 週期',
            value: _draft.kdPeriod.toDouble(),
            min: 5,
            max: 30,
            divisions: 25,
            onChanged: (v) =>
                setState(() => _draft = _draft.copyWith(kdPeriod: v.toInt())),
          ),
          _slider(
            label: 'BIAS 週期',
            value: _draft.biasPeriod.toDouble(),
            min: 5,
            max: 60,
            divisions: 55,
            onChanged: (v) => setState(
                () => _draft = _draft.copyWith(biasPeriod: v.toInt())),
          ),
          _slider(
            label: 'W%R 週期',
            value: _draft.williamsPeriod.toDouble(),
            min: 5,
            max: 30,
            divisions: 25,
            onChanged: (v) => setState(
                () => _draft = _draft.copyWith(williamsPeriod: v.toInt())),
          ),
          const SizedBox(height: 20),
          _section('MACD'),
          _slider(
            label: '快線',
            value: _draft.macdFast.toDouble(),
            min: 2,
            max: 30,
            divisions: 28,
            onChanged: (v) =>
                setState(() => _draft = _draft.copyWith(macdFast: v.toInt())),
          ),
          _slider(
            label: '慢線',
            value: _draft.macdSlow.toDouble(),
            min: 5,
            max: 60,
            divisions: 55,
            onChanged: (v) =>
                setState(() => _draft = _draft.copyWith(macdSlow: v.toInt())),
          ),
          _slider(
            label: '信號線',
            value: _draft.macdSignal.toDouble(),
            min: 3,
            max: 20,
            divisions: 17,
            onChanged: (v) => setState(
                () => _draft = _draft.copyWith(macdSignal: v.toInt())),
          ),
          const SizedBox(height: 20),
          _section('布林通道'),
          _slider(
            label: '週期',
            value: _draft.bollingerPeriod.toDouble(),
            min: 5,
            max: 60,
            divisions: 55,
            onChanged: (v) => setState(() =>
                _draft = _draft.copyWith(bollingerPeriod: v.toInt())),
          ),
          _slider(
            label: '標準差倍數',
            value: _draft.bollingerStdDev,
            min: 1.0,
            max: 3.0,
            divisions: 8,
            valueLabel: _draft.bollingerStdDev.toStringAsFixed(2),
            onChanged: (v) => setState(
                () => _draft = _draft.copyWith(bollingerStdDev: v)),
          ),
          const SizedBox(height: 20),
          _section('ATR'),
          _slider(
            label: '週期',
            value: _draft.atrPeriod.toDouble(),
            min: 5,
            max: 30,
            divisions: 25,
            onChanged: (v) =>
                setState(() => _draft = _draft.copyWith(atrPeriod: v.toInt())),
          ),
        ],
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 8),
        child: Text(
          title,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  Widget _intField(String label, TextEditingController c) => TextField(
        controller: c,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
        ),
      );

  Widget _slider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required void Function(double) onChanged,
    String? valueLabel,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label)),
          Expanded(
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              label: valueLabel ?? value.toInt().toString(),
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              valueLabel ?? value.toInt().toString(),
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: AppTheme.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
