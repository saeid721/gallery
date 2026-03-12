import 'media_item.dart';

// ─────────────────────────────────────────────────────────────
// MEDIA GROUP MODEL
// Groups photos into: Today, Yesterday, This Week, Month Year
// ─────────────────────────────────────────────────────────────

class MediaGroup {
  final String          label;
  final List<MediaItem> items;

  const MediaGroup({required this.label, required this.items});

  static List<MediaGroup> groupByDate(List<MediaItem> items) {
    if (items.isEmpty) return [];

    final now       = DateTime.now();
    final today     = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekStart = today.subtract(const Duration(days: 6));

    final map = <String, List<MediaItem>>{};

    for (final item in items) {
      final d   = item.dateTime;
      final day = DateTime(d.year, d.month, d.day);

      final String label;
      if (!day.isBefore(today)) {
        label = 'Today';
      } else if (!day.isBefore(yesterday)) {
        label = 'Yesterday';
      } else if (!day.isBefore(weekStart)) {
        label = 'This Week';
      } else {
        label = _monthYear(d);
      }

      (map[label] ??= []).add(item);
    }

    return map.entries
        .map((e) => MediaGroup(label: e.key, items: e.value))
        .toList();
  }

  static String _monthYear(DateTime d) {
    const months = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December',
    ];
    return '${months[d.month - 1]} ${d.year}';
  }
}