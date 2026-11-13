enum ShortPlatform {
  tiktok,
  youtubeShorts,
  instagramReels;

  String get label => switch (this) {
    ShortPlatform.tiktok => 'TikTok',
    ShortPlatform.youtubeShorts => 'YouTube Shorts',
    ShortPlatform.instagramReels => 'Instagram Reels',
  };

  int get dailyLimit => switch (this) {
    ShortPlatform.tiktok => 5,
    ShortPlatform.youtubeShorts => 2,
    ShortPlatform.instagramReels => 3,
  };

  Uri get startUri => switch (this) {
    ShortPlatform.tiktok => Uri.https('www.tiktok.com', '/foryou'),
    ShortPlatform.youtubeShorts => Uri.https('www.youtube.com', '/shorts'),
    ShortPlatform.instagramReels => Uri.https('www.instagram.com', '/reels/'),
  };

  List<String> get allowedHosts => switch (this) {
    ShortPlatform.tiktok => const ['tiktok.com'],
    ShortPlatform.youtubeShorts => const ['youtube.com', 'google.com'],
    ShortPlatform.instagramReels => const ['instagram.com', 'facebook.com'],
  };

  // Group 1 captures the id of the short currently shown in the page URL.
  String get viewIdPattern => switch (this) {
    ShortPlatform.tiktok => r'\/video\/(\d+)',
    ShortPlatform.youtubeShorts => r'\/shorts\/([A-Za-z0-9_-]+)',
    ShortPlatform.instagramReels => r'\/reels?\/([A-Za-z0-9_-]+)',
  };
}
