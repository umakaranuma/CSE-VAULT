import 'package:intl/intl.dart';

class Formatters {
  static String currency(double value) {
    final format = NumberFormat.currency(locale: 'en_LK', symbol: '', decimalDigits: 2);
    return format.format(value).trim();
  }

  static String compactCurrency(double value) {
    if (value.abs() >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(2)}M';
    } else if (value.abs() >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(2);
  }

  static String percentage(double value) {
    return '${value >= 0 ? '+' : ''}${value.toStringAsFixed(2)}%';
  }

  static String formatDate(DateTime dt) {
    return DateFormat('dd MMM HH:mm').format(dt);
  }

  static String formatDateLong(DateTime dt) {
    return DateFormat('dd MMM yyyy HH:mm').format(dt);
  }

  static String formatTime(DateTime dt) {
    return DateFormat('hh:mm a').format(dt);
  }

  static String formatDateWithDay(DateTime dt) {
    return DateFormat('EEE, dd MMM').format(dt);
  }

  static String formatDateOnly(DateTime dt) {
    return DateFormat('dd MMM yyyy').format(dt);
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
