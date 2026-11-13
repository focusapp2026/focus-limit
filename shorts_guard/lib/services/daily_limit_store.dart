import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/daily_usage.dart';
import '../models/short_video.dart';

class DailyLimitStore {
  static const _videosKey = 'saved_videos_v1';
  static const _usageKey = 'daily_usage_v1';

  Future<List<ShortVideo>> loadVideos() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_videosKey);
    if (raw == null) return [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('قائمة الفيديوهات المحفوظة تالفة.');
    }
    return decoded
        .map((item) => ShortVideo.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> addVideo(ShortVideo video) async {
    final videos = await loadVideos();
    videos.insert(0, video);
    await _saveVideos(videos);
  }

  Future<void> removeVideo(String videoId) async {
    final videos = await loadVideos();
    videos.removeWhere((video) => video.id == videoId);
    await _saveVideos(videos);
  }

  Future<DailyUsage> loadUsage() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_usageKey);
    if (raw == null) {
      final freshUsage = DailyUsage.today();
      await _saveUsage(preferences, freshUsage);
      return freshUsage;
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('بيانات رصيد اليوم تالفة.');
    }

    final savedUsage = DailyUsage.fromJson(decoded);
    if (savedUsage.dayKey != DailyUsage.todayKey()) {
      final freshUsage = DailyUsage.today();
      await _saveUsage(preferences, freshUsage);
      return freshUsage;
    }
    return savedUsage;
  }

  Future<bool> consume(VideoPlatform platform) async {
    final preferences = await SharedPreferences.getInstance();
    final usage = await loadUsage();
    if (usage.countFor(platform) >= platform.dailyLimit) return false;

    await _saveUsage(preferences, usage.increment(platform));
    return true;
  }

  Future<void> _saveVideos(List<ShortVideo> videos) async {
    final preferences = await SharedPreferences.getInstance();
    final success = await preferences.setString(
      _videosKey,
      jsonEncode(videos.map((video) => video.toJson()).toList()),
    );
    if (!success) throw StateError('تعذر حفظ قائمة الفيديوهات.');
  }

  Future<void> _saveUsage(
    SharedPreferences preferences,
    DailyUsage usage,
  ) async {
    final success = await preferences.setString(
      _usageKey,
      jsonEncode(usage.toJson()),
    );
    if (!success) throw StateError('تعذر حفظ رصيد اليوم.');
  }
}
