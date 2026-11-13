import 'short_platform.dart';

class DailyUsage {
  const DailyUsage({required this.dayKey, required this.viewedIds});

  factory DailyUsage.today() =>
      DailyUsage(dayKey: todayKey(), viewedIds: const {});

  final String dayKey;
  final Map<String, List<String>> viewedIds;

  static String todayKey([DateTime? date]) {
    final now = date ?? DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  static Duration timeUntilReset([DateTime? now]) {
    final current = now ?? DateTime.now();
    final nextMidnight = DateTime(current.year, current.month, current.day + 1);
    return nextMidnight.difference(current);
  }

  int countFor(ShortPlatform platform) => viewedIds[platform.name]?.length ?? 0;

  int remainingFor(ShortPlatform platform) =>
      (platform.dailyLimit - countFor(platform)).clamp(0, platform.dailyLimit);

  bool hasViewed(ShortPlatform platform, String viewId) =>
      viewedIds[platform.name]?.contains(viewId) ?? false;

  DailyUsage withView(ShortPlatform platform, String viewId) {
    final updated = {
      for (final entry in viewedIds.entries)
        entry.key: List<String>.of(entry.value),
    };
    updated.update(
      platform.name,
      (ids) => [...ids, viewId],
      ifAbsent: () => [viewId],
    );
    return DailyUsage(dayKey: dayKey, viewedIds: updated);
  }

  factory DailyUsage.fromJson(Map<String, dynamic> json) {
    final rawViews = json['viewedIds'] as Map<String, dynamic>;
    return DailyUsage(
      dayKey: json['dayKey'] as String,
      viewedIds: rawViews.map(
        (platform, ids) =>
            MapEntry(platform, (ids as List<dynamic>).cast<String>()),
      ),
    );
  }

  Map<String, Object?> toJson() => {'dayKey': dayKey, 'viewedIds': viewedIds};
}
