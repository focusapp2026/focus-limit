import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shorts_guard/models/short_platform.dart';
import 'package:shorts_guard/services/daily_limit_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('يسمح بالحد اليومي لكل منصة ثم يتوقف العداد', () async {
    final store = DailyLimitStore();

    for (final platform in ShortPlatform.values) {
      for (var index = 0; index < platform.dailyLimit + 2; index++) {
        await store.recordView(platform, '${platform.name}-$index');
      }
    }

    final usage = await store.loadUsage();
    expect(usage.countFor(ShortPlatform.tiktok), 5);
    expect(usage.countFor(ShortPlatform.youtubeShorts), 5);
    expect(usage.countFor(ShortPlatform.instagramReels), 5);
    expect(usage.countFor(ShortPlatform.youtubeLong), 2);
    expect(usage.remainingFor(ShortPlatform.tiktok), 0);
  });

  test('لا يحتسب الفيديو نفسه مرتين', () async {
    final store = DailyLimitStore();

    await store.recordView(ShortPlatform.youtubeLong, 'a');
    await store.recordView(ShortPlatform.youtubeLong, 'a');

    final usage = await store.loadUsage();
    expect(usage.countFor(ShortPlatform.youtubeLong), 1);
  });

  test('صفحات تسجيل الدخول لا تُحتسب', () {
    expect(
      ShortPlatform.youtubeLong.countsPage(
        Uri.parse('https://accounts.google.com/v3/signin/identifier'),
      ),
      isFalse,
    );
    expect(
      ShortPlatform.tiktok.countsPage(
        Uri.parse('https://www.tiktok.com/login/phone-or-email'),
      ),
      isFalse,
    );
    expect(
      ShortPlatform.youtubeLong.countsPage(
        Uri.parse('https://www.youtube.com/watch?v=abcdefghijk'),
      ),
      isTrue,
    );
  });
}
