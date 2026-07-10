import 'package:intl/intl.dart';

/// Utility methods for formatting monetary values.
class CurrencyFormatter {
  CurrencyFormatter._();

  static final _compact = NumberFormat.compact(locale: 'en_IN');
  static final _full = NumberFormat('#,##,##0.00', 'en_IN');
  static final _noDecimal = NumberFormat('#,##,##0', 'en_IN');

  static const String _symbol = '₹';

  /// Full format with symbol — e.g. "₹1,23,456.78"
  static String format(double amount) => '$_symbol${_full.format(amount)}';

  /// Compact format — e.g. "₹1.2L" or "₹12K"
  static String compact(double amount) => '$_symbol${_compact.format(amount)}';

  /// No-decimal format — e.g. "₹1,23,456"
  static String formatInt(double amount) =>
      '$_symbol${_noDecimal.format(amount)}';

  /// Just the number string without symbol.
  static String numberOnly(double amount) => _full.format(amount);
}
