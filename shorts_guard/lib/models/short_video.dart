enum VideoPlatform {
  tiktok,
  youtube;

  String get label => switch (this) {
    VideoPlatform.tiktok => 'TikTok',
    VideoPlatform.youtube => 'YouTube',
  };

  int get dailyLimit => switch (this) {
    VideoPlatform.tiktok => 5,
    VideoPlatform.youtube => 2,
  };
}

class ParsedVideoLink {
  const ParsedVideoLink({
    required this.platform,
    required this.videoId,
    required this.sourceUrl,
  });

  final VideoPlatform platform;
  final String videoId;
  final String sourceUrl;

  Uri get playerUri => switch (platform) {
    VideoPlatform.tiktok => Uri.https(
      'www.tiktok.com',
      '/player/v1/$videoId',
      const {'music_info': '1', 'description': '1'},
    ),
    VideoPlatform.youtube => Uri.https(
      'www.youtube.com',
      '/embed/$videoId',
      const {'playsinline': '1', 'enablejsapi': '1', 'rel': '0'},
    ),
  };

  static ParsedVideoLink? parse(String raw) {
    final input = raw.trim();
    if (input.isEmpty) return null;

    final normalized = input.contains('://') ? input : 'https://$input';
    final uri = Uri.tryParse(normalized);
    if (uri == null || !uri.hasAuthority || uri.host.isEmpty) return null;

    final host = uri.host.toLowerCase();

    if (_isHost(host, 'youtube.com') ||
        _isHost(host, 'youtube-nocookie.com') ||
        host == 'youtu.be') {
      final id = _youtubeId(uri, host);
      if (id == null) return null;
      return ParsedVideoLink(
        platform: VideoPlatform.youtube,
        videoId: id,
        sourceUrl: uri.toString(),
      );
    }

    if (_isHost(host, 'tiktok.com')) {
      final match = RegExp(r'/video/([0-9]+)').firstMatch(uri.path);
      if (match == null) return null;
      return ParsedVideoLink(
        platform: VideoPlatform.tiktok,
        videoId: match.group(1)!,
        sourceUrl: uri.toString(),
      );
    }

    return null;
  }

  static String validationMessage(String raw) {
    final input = raw.trim();
    if (input.isEmpty) return 'أضف رابط فيديو أولاً.';

    final normalized = input.contains('://') ? input : 'https://$input';
    final uri = Uri.tryParse(normalized);
    if (uri == null || !uri.hasAuthority || uri.host.isEmpty) {
      return 'تأكد من كتابة رابط صالح يبدأ بـ https://.';
    }

    final host = uri.host.toLowerCase();
    if (_isHost(host, 'tiktok.com')) {
      return 'استخدم رابط فيديو TikTok الكامل الذي يحتوي على /video/.';
    }
    if (_isHost(host, 'youtube.com') ||
        _isHost(host, 'youtube-nocookie.com') ||
        host == 'youtu.be') {
      return 'تعذر العثور على معرّف الفيديو في هذا الرابط.';
    }
    return 'الرابط يجب أن يكون لفيديو من TikTok أو YouTube.';
  }

  static bool _isHost(String host, String domain) =>
      host == domain || host.endsWith('.$domain');

  static String? _youtubeId(Uri uri, String host) {
    String? id;
    if (host == 'youtu.be') {
      id = uri.pathSegments.isEmpty ? null : uri.pathSegments.first;
    } else if (uri.path == '/watch') {
      id = uri.queryParameters['v'];
    } else if (uri.pathSegments.length >= 2 &&
        const {'shorts', 'embed', 'live'}.contains(uri.pathSegments.first)) {
      id = uri.pathSegments[1];
    }

    if (id == null || !RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(id)) {
      return null;
    }
    return id;
  }
}

class ShortVideo {
  const ShortVideo({
    required this.id,
    required this.title,
    required this.platform,
    required this.videoId,
    required this.sourceUrl,
  });

  final String id;
  final String title;
  final VideoPlatform platform;
  final String videoId;
  final String sourceUrl;

  Uri get playerUri => ParsedVideoLink(
    platform: platform,
    videoId: videoId,
    sourceUrl: sourceUrl,
  ).playerUri;

  factory ShortVideo.fromLink({
    required String title,
    required ParsedVideoLink link,
  }) {
    return ShortVideo(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      platform: link.platform,
      videoId: link.videoId,
      sourceUrl: link.sourceUrl,
    );
  }

  factory ShortVideo.fromJson(Map<String, dynamic> json) {
    final platformName = json['platform'];
    final platform = VideoPlatform.values.firstWhere(
      (value) => value.name == platformName,
      orElse: () => throw const FormatException('منصة الفيديو غير معروفة.'),
    );

    return ShortVideo(
      id: json['id'] as String,
      title: json['title'] as String,
      platform: platform,
      videoId: json['videoId'] as String,
      sourceUrl: json['sourceUrl'] as String,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'platform': platform.name,
    'videoId': videoId,
    'sourceUrl': sourceUrl,
  };
}
