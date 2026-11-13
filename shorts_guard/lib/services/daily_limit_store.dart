import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/daily_usage.dart';
import '../models/short_platform.dart';

enum ViewOutcome { counted, alreadyCounted, limitReached }

typedef ViewResult = ({DailyUsage usage, ViewOutcome outcome});

class DailyLimitStore {
  static const _usageKey = 'daily_usage_v2';

  Future<DailyUsage> loadUsage() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_usageKey);
    if (raw == null) return _resetUsage(preferences);

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('بيانات رصيد اليوم تالفة.');
    }

    final savedUsage = DailyUsage.fromJson(decoded);
    if (savedUsage.dayKey != DailyUsage.todayKey()) {
      return _resetUsage(preferences);
    }
    return savedUsage;
  }

  Future<ViewResult> recordView(ShortPlatform platform, String viewId) async {
    final preferences = await SharedPreferences.getInstance();
    final usage = await loadUsage();
    if (usage.hasViewed(platform, viewId)) {
      return (usage: usage, outcome: ViewOutcome.alreadyCounted);
    }
    if (usage.remainingFor(platform) == 0) {
      return (usage: usage, outcome: ViewOutcome.limitReached);
    }

    final updated = usage.withView(platform, viewId);
    await _saveUsage(preferences, updated);
    return (usage: updated, outcome: ViewOutcome.counted);
  }

  Future<DailyUsage> _resetUsage(SharedPreferences preferences) async {
    final freshUsage = DailyUsage.today();
    await _saveUsage(preferences, freshUsage);
    return freshUsage;
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
