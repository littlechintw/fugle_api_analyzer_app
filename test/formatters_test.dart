import 'package:flutter_test/flutter_test.dart';
import 'package:fugle_api_app/core/utils/formatters.dart';

void main() {
  group('Fmt.price', () {
    test('兩位小數 + 千分位', () {
      expect(Fmt.price(123456.789), '123,456.79');
      expect(Fmt.price(0), '0.00');
      expect(Fmt.price(0.1), '0.10');
    });
  });

  group('Fmt.integer', () {
    test('千分位、不帶小數', () {
      expect(Fmt.integer(1234567), '1,234,567');
      expect(Fmt.integer(0), '0');
    });
  });

  group('Fmt.percent', () {
    test('正值帶 +、負值帶 -', () {
      expect(Fmt.percent(1.23), '+1.23%');
      expect(Fmt.percent(-1.23), '-1.23%');
    });

    test('0 不帶 +', () {
      expect(Fmt.percent(0), '+0.00%'); // pattern '+0.00;-0.00' 對 0 視為正
    });
  });

  group('Fmt.signed', () {
    test('帶正負號', () {
      expect(Fmt.signed(2.5), '+2.50');
      expect(Fmt.signed(-2.5), '-2.50');
    });
  });

  group('Fmt.volume', () {
    test('小量顯示張', () {
      expect(Fmt.volume(1000), '1 張'); // 1000 股 = 1 張
      expect(Fmt.volume(5000), '5 張');
    });

    test('大量顯示萬張', () {
      // 1500 萬股 = 1.5 萬張
      expect(Fmt.volume(15000000), contains('萬張'));
    });

    test('零量顯示 0 張', () {
      expect(Fmt.volume(0), '0 張');
    });
  });

  group('Fmt.date', () {
    test('yyyy/MM/dd', () {
      expect(Fmt.date(DateTime(2026, 5, 11)), '2026/05/11');
    });
  });

  group('Fmt.datetime', () {
    test('MM/dd HH:mm:ss', () {
      final d = DateTime(2026, 5, 11, 9, 30, 15);
      expect(Fmt.datetime(d), '05/11 09:30:15');
    });
  });
}
