class TimeUtils {
  static DateTime? parseToLocal(dynamic timestamp) {
    if (timestamp == null) return null;
    final str = timestamp.toString().trim();
    if (str.isEmpty) return null;
    try {
      final parsed = DateTime.parse(str);
      return parsed.isUtc ? parsed.toLocal() : parsed;
    } catch (_) {
      return null;
    }
  }

  static String formatVietnamTime(dynamic timestamp) {
    final dt = parseToLocal(timestamp);
    if (dt == null) return timestamp?.toString() ?? '';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    return '$h:$m - $d/$mo/$y';
  }

  static String formatShortTime(dynamic timestamp) {
    final dt = parseToLocal(timestamp);
    if (dt == null) return timestamp?.toString() ?? '';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String formatDateOnly(dynamic timestamp) {
    final dt = parseToLocal(timestamp);
    if (dt == null) return timestamp?.toString().split('T')[0] ?? '';
    final d = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    return '$y-$mo-$d';
  }
}
