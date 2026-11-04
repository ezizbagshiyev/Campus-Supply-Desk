import 'package:flutter_test/flutter_test.dart';
import 'package:incl12b/main.dart';

void main() {
  final fixtures = <Map<String, dynamic>>[
    {'name': 'Maple Notebook', 'price': 9.75},
    {'name': 'Campus Pen Set', 'price': 16.50},
    {'name': 'Study Lamp', 'price': 29.00},
    {'name': 'maple Bookmark', 'price': 4.25},
    {'name': 'Welcome Sample', 'price': 0.00},
  ];
  int count(String q, double? min, double? max) => fixtures
      .where((p) => matchesProduct(p, q, min, max)).length;
  test('Variant B search is case insensitive and matches substrings', () {
    expect(count('mApLe', null, null), 2);
    expect(count('book', null, null), 2);
    expect(count('no-such-product', null, null), 0);
  });
  test('Variant B inclusive, combined, equal, open bounds and reset counts', () {
    expect(count('', 4.25, 16.50), 3);
    expect(count('maple', 4.25, 16.50), 2);
    expect(count('', 9.75, 9.75), 1);
    expect(count('', 16.50, null), 2);
    expect(count('', null, 4.25), 2);
    expect(count('', null, null), 5);
    expect(count('', 40, 50), 0);
  });
  test('Prices reject invalid data and accept zero', () {
    for (final s in ['', ' ', 'abc', '-1', 'NaN', 'Infinity']) {
      expect(parseAmount(s), isNull);
    }
    expect(parseAmount('0'), 0);
    expect(validProduct({'name': ' ', 'price': 1}), isFalse);
    expect(validProduct({'name': 'Kit', 'price': '9.75'}), isFalse);
    expect(validProduct({'name': 'Kit', 'price': double.nan}), isFalse);
  });
}
