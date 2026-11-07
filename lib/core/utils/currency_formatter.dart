class CurrencyFormatter {
  /// Format integer rupiah menjadi string dengan pemisah ribuan titik.
  /// Contoh: 1500000 -> "Rp 1.500.000"
  static String format(int amount) {
    final negative = amount < 0;
    final str = amount.abs().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return '${negative ? "-" : ""}Rp $buffer';
  }

  /// Parse string "1.500.000" atau "1500000" menjadi int.
  static int parse(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return 0;
    return int.tryParse(cleaned) ?? 0;
  }
}