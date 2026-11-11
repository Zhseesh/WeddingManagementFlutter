import 'package:flutter_test/flutter_test.dart';
import 'package:weddingmanagementf/core/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter.format', () {
    test('zero', () => expect(CurrencyFormatter.format(0), 'Rp 0'));
    test('thousands', () => expect(CurrencyFormatter.format(1500000), 'Rp 1.500.000'));
    test('negative', () => expect(CurrencyFormatter.format(-5000), '-Rp 5.000'));
  });
  group('CurrencyFormatter.parse', () {
    test('dotted', () => expect(CurrencyFormatter.parse('1.500.000'), 1500000));
    test('empty', () => expect(CurrencyFormatter.parse(''), 0));
    test('garbage', () => expect(CurrencyFormatter.parse('abc'), 0));
  });
  group('CurrencyFormatter.shortFormat', () {
    test('million', () => expect(CurrencyFormatter.shortFormat(1500000), '1,5Jt'));
    test('billion', () => expect(CurrencyFormatter.shortFormat(5000000000), '5M'));
  });
}