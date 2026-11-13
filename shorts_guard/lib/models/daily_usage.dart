import 'short_video.dart';

class DailyUsage {
  const DailyUsage({
    required this.dayKey,
    required this.tiktokWatched,
    required this.youtubeWatched,
  });

  factory DailyUsage.today() =>
      DailyUsage(dayKey: todayKey(), tiktokWatched: 0, youtubeWatched: 0);

  final String dayKey;
  final int tiktokWatched;
  final int youtubeWatched;

  static String todayKey([DateTime? date]) {
    final now = date ?? DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  int countFor(VideoPlatform platform) => switch (platform) {
    VideoPlatform.tiktok => tiktokWatched,
    VideoPlatform.youtube => youtubeWatched,
  };

  int remainingFor(VideoPlatform platform) =>
      (platform.dailyLimit - countFor(platform)).clamp(0, platform.dailyLimit);

  DailyUsage increment(VideoPlatform platform) => DailyUsage(
    dayKey: dayKey,
    tiktokWatched: tiktokWatched + (platform == VideoPlatform.tiktok ? 1 : 0),
    youtubeWatched:
        youtubeWatched + (platform == VideoPlatform.youtube ? 1 : 0),
  );

  factory DailyUsage.fromJson(Map<String, dynamic> json) => DailyUsage(
    dayKey: json['dayKey'] as String,
    tiktokWatched: json['tiktokWatched'] as int,
    youtubeWatched: json['youtubeWatched'] as int,
  );

  Map<String, Object?> toJson() => {
    'dayKey': dayKey,
    'tiktokWatched': tiktokWatched,
    'youtubeWatched': youtubeWatched,
  };
}
