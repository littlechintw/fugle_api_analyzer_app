import 'package:intl/intl.dart';

class Fmt {
  static final _price = NumberFormat('#,##0.00');
  static final _int = NumberFormat('#,##0');
  static final _percent = NumberFormat('+0.00;-0.00');
  static final _date = DateFormat('yyyy/MM/dd');
  static final _datetime = DateFormat('MM/dd HH:mm:ss');

  static String price(num v) => _price.format(v);
  static String integer(num v) => _int.format(v);
  static String percent(num v) => '${_percent.format(v)}%';
  static String signed(num v) => _percent.format(v);
  static String date(DateTime d) => _date.format(d);
  static String datetime(DateTime d) => _datetime.format(d);

  /// 將「股」單位的成交量轉成顯示用字串 (張 / 千張)
  static String volume(num shares) {
    final lots = shares / 1000;
    if (lots >= 10000) return '${(lots / 10000).toStringAsFixed(2)} 萬張';
    return '${_int.format(lots.round())} 張';
  }
}
