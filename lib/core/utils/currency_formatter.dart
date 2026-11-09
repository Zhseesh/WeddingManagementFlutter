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

  /// Format singkat untuk space terbatas (mis. center donut chart).
  /// Contoh:
  ///   57000000        -> "57Jt"
  ///   1500000         -> "1,5Jt"
  ///   5000000000      -> "5M"
  ///   500000          -> "500Rb"
  ///   500             -> "500"
  static String shortFormat(int amount) {
    if (amount == 0) return '0';
    final abs = amount.abs();
    final sign = amount < 0 ? '-' : '';

    String fmt(double v, String suffix) {
      final isWhole = v == v.truncateToDouble();
      final str = isWhole ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
      return '$sign${str.replaceAll('.', ',')}$suffix';
    }

    if (abs >= 1000000000000) return fmt(abs / 1000000000000, 'T');
    if (abs >= 1000000000) return fmt(abs / 1000000000, 'M');
    if (abs >= 1000000) return fmt(abs / 1000000, 'Jt');
    if (abs >= 1000) return fmt(abs / 1000, 'Rb');
    return '$sign$abs';
  }

  /// Parse string "1.500.000" atau "1500000" menjadi int.
  static int parse(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return 0;
    return int.tryParse(cleaned) ?? 0;
  }
}