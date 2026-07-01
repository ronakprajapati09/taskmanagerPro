import 'package:intl/intl.dart';

/// Date helpers shared across the app. Pure functions, easy to unit test.
class AppDateUtils {
  AppDateUtils._();

  static bool isSameDate(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool isToday(DateTime? date) => isSameDate(date, DateTime.now());

  static bool isOverdue(DateTime? due) {
    if (due == null) return false;
    final now = DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return due.isBefore(endOfToday) && !isSameDate(due, now)
        ? due.isBefore(DateTime(now.year, now.month, now.day))
        : false;
  }

  static bool isUpcoming(DateTime? due) {
    if (due == null) return false;
    final now = DateTime.now();
    final startOfTomorrow = DateTime(now.year, now.month, now.day + 1);
    return !due.isBefore(startOfTomorrow);
  }

  static String formatDate(DateTime date) =>
      DateFormat('MMM d, yyyy').format(date);

  static String formatDateTime(DateTime date) =>
      DateFormat('MMM d, yyyy • h:mm a').format(date);

  static String formatTime(DateTime date) => DateFormat('h:mm a').format(date);

  /// Friendly relative label for a due date.
  static String relativeLabel(DateTime due) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(due.year, due.month, due.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    if (diff < 0) return '${-diff} days ago';
    if (diff < 7) return 'In $diff days';
    return formatDate(due);
  }
}

