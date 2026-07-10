import 'package:intl/intl.dart';

/// Utility methods for formatting dates and times consistently.
class DateFormatter {
  DateFormatter._();

  static final _dayMonth = DateFormat('d MMM');
  static final _dayMonthYear = DateFormat('d MMM yyyy');
  static final _shortDate = DateFormat('dd/MM/yy');
  static final _isoDate = DateFormat('yyyy-MM-dd');
  static final _fullDate = DateFormat('EEEE, d MMMM yyyy');
  static final _monthYear = DateFormat('MMMM yyyy');
  static final _dayName = DateFormat('EEE');
  static final _shortMonth = DateFormat('MMM');

  /// e.g. "8 Jul"
  static String toDayMonth(DateTime dt) => _dayMonth.format(dt);

  /// e.g. "8 Jul 2025"
  static String toDayMonthYear(DateTime dt) => _dayMonthYear.format(dt);

  /// e.g. "08/07/25"
  static String toShortDate(DateTime dt) => _shortDate.format(dt);

  /// e.g. "2025-07-08"
  static String toIso(DateTime dt) => _isoDate.format(dt);

  /// e.g. "Tuesday, 8 July 2025"
  static String toFullDate(DateTime dt) => _fullDate.format(dt);

  /// e.g. "July 2025"
  static String toMonthYear(DateTime dt) => _monthYear.format(dt);

  /// e.g. "Mon"
  static String toDayName(DateTime dt) => _dayName.format(dt);

  /// e.g. "Jul"
  static String toShortMonth(DateTime dt) => _shortMonth.format(dt);

  /// Parses an ISO-8601 date string back to DateTime.
  static DateTime fromIso(String iso) => DateTime.parse(iso);

  /// Returns true if two DateTimes are on the same calendar day.
  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Returns the start of today (midnight).
  static DateTime get todayStart {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Returns the start of this month.
  static DateTime get monthStart {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  /// Returns the end of this month (last millisecond of last day).
  static DateTime get monthEnd {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 1)
        .subtract(const Duration(milliseconds: 1));
  }

  /// Returns start-of-day for [date].
  static DateTime startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Returns a list of the last [days] calendar days (oldest first).
  static List<DateTime> lastNDays(int days) {
    final today = startOfDay(DateTime.now());
    return List.generate(
        days, (i) => today.subtract(Duration(days: days - 1 - i)));
  }
}
