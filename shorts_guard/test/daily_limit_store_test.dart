import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shorts_guard/models/short_video.dart';
import 'package:shorts_guard/services/daily_limit_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('يسمح بخمسة فيديوهات TikTok وفيديوهين YouTube فقط', () async {
    final store = DailyLimitStore();

    for (var index = 0; index < 5; index++) {
      expect(await store.consume(VideoPlatform.tiktok), isTrue);
    }
    expect(await store.consume(VideoPlatform.tiktok), isFalse);

    for (var index = 0; index < 2; index++) {
      expect(await store.consume(VideoPlatform.youtube), isTrue);
    }
    expect(await store.consume(VideoPlatform.youtube), isFalse);

    final usage = await store.loadUsage();
    expect(usage.tiktokWatched, 5);
    expect(usage.youtubeWatched, 2);
  });
}
