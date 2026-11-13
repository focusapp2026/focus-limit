enum ShortPlatform {
  tiktok,
  youtubeShorts,
  instagramReels,
  youtubeLong;

  String get label => switch (this) {
    ShortPlatform.tiktok => 'TikTok',
    ShortPlatform.youtubeShorts => 'YouTube Shorts',
    ShortPlatform.instagramReels => 'Instagram Reels',
    ShortPlatform.youtubeLong => 'YouTube Long',
  };

  int get dailyLimit => switch (this) {
    ShortPlatform.tiktok => 5,
    ShortPlatform.youtubeShorts => 5,
    ShortPlatform.instagramReels => 5,
    ShortPlatform.youtubeLong => 2,
  };

  Uri get startUri => switch (this) {
    ShortPlatform.tiktok => Uri.https('www.tiktok.com', '/foryou'),
    ShortPlatform.youtubeShorts => Uri.https('www.youtube.com', '/shorts'),
    ShortPlatform.instagramReels => Uri.https('www.instagram.com', '/reels/'),
    ShortPlatform.youtubeLong => Uri.https('www.youtube.com', '/'),
  };

  List<String> get contentHosts => switch (this) {
    ShortPlatform.tiktok => const ['tiktok.com'],
    ShortPlatform.youtubeShorts => const ['youtube.com'],
    ShortPlatform.instagramReels => const ['instagram.com'],
    ShortPlatform.youtubeLong => const ['youtube.com'],
  };

  List<String> get allowedHosts => [...contentHosts, ..._signInHosts];

  // Group 1 captures the id of the video currently shown in the page URL.
  String get viewIdPattern => switch (this) {
    ShortPlatform.tiktok => r'\/video\/(\d+)',
    ShortPlatform.youtubeShorts => r'\/shorts\/([A-Za-z0-9_-]+)',
    ShortPlatform.instagramReels => r'\/reels?\/([A-Za-z0-9_-]+)',
    ShortPlatform.youtubeLong => r'\/watch\?(?:.*&)?v=([A-Za-z0-9_-]+)',
  };

  // Feeds without an id in the URL are identified by the playing video's source.
  bool get detectsPlayingMedia =>
      this == ShortPlatform.tiktok || this == ShortPlatform.instagramReels;

  bool get isLong => this == ShortPlatform.youtubeLong;

  bool countsPage(Uri uri) =>
      hostMatches(uri, contentHosts) && !isAuthPage(uri);

  bool allowsNavigation(Uri uri) =>
      hostMatches(uri, allowedHosts) || isAuthPage(uri);

  bool isAuthPage(Uri uri) =>
      hostMatches(uri, _signInHosts) ||
      uri.pathSegments.any(
        (segment) => _authSegments.contains(segment.toLowerCase()),
      );
}

const _signInHosts = ['google.com', 'apple.com', 'facebook.com'];

const _authSegments = {
  'login',
  'signin',
  'sign-in',
  'accounts',
  'auth',
  'oauth',
  'oauth2',
  'callback',
};

bool hostMatches(Uri uri, List<String> domains) {
  final host = uri.host.toLowerCase();
  return domains.any((domain) => host == domain || host.endsWith('.$domain'));
}
