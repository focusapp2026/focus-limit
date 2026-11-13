import 'package:flutter_test/flutter_test.dart';
import 'package:shorts_guard/models/short_video.dart';

void main() {
  group('رابط الفيديو', () {
    test('يتعرف على رابط YouTube Shorts', () {
      final link = ParsedVideoLink.parse(
        'https://www.youtube.com/shorts/AbCdEfGh123',
      );

      expect(link, isNotNull);
      expect(link!.platform, VideoPlatform.youtube);
      expect(link.videoId, 'AbCdEfGh123');
      expect(link.playerUri.host, 'www.youtube.com');
    });

    test('يتعرف على رابط TikTok مباشر', () {
      final link = ParsedVideoLink.parse(
        'https://www.tiktok.com/@creator/video/1234567890123456789',
      );

      expect(link, isNotNull);
      expect(link!.platform, VideoPlatform.tiktok);
      expect(link.videoId, '1234567890123456789');
      expect(link.playerUri.path, '/player/v1/1234567890123456789');
    });

    test('يرفض الروابط غير المعروفة وروابط TikTok المختصرة', () {
      expect(ParsedVideoLink.parse('https://example.com/video'), isNull);
      expect(ParsedVideoLink.parse('https://vm.tiktok.com/abc123/'), isNull);
    });
  });
}
