import 'package:flutter/material.dart';

import '../models/daily_usage.dart';
import '../models/short_platform.dart';
import 'lock_countdown.dart';

class PlatformCard extends StatelessWidget {
  const PlatformCard({
    required this.platform,
    required this.usage,
    required this.onOpen,
    required this.onReset,
    super.key,
  });

  final ShortPlatform platform;
  final DailyUsage usage;
  final VoidCallback onOpen;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final accent = _accentFor(platform);
    final remaining = usage.remainingFor(platform);
    final isLocked = remaining == 0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: isLocked ? null : onOpen,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE7EAE4)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(_iconFor(platform), color: accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      platform.label,
                      style: const TextStyle(
                        color: Color(0xFF18231F),
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isLocked
                          ? 'مغلق حتى الغد'
                          : 'باقي $remaining من ${platform.dailyLimit} ${platform.isLong ? 'فيديوهات طويلة' : 'فيديوهات'} اليوم',
                      style: TextStyle(
                        color: isLocked
                            ? const Color(0xFF9B443B)
                            : const Color(0xFF68736D),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isLocked) ...[
                      const SizedBox(height: 6),
                      LockCountdown(
                        onReset: onReset,
                        style: const TextStyle(
                          color: Color(0xFF9B443B),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                isLocked ? Icons.lock_rounded : Icons.chevron_left_rounded,
                color: isLocked
                    ? const Color(0xFF9B443B)
                    : const Color(0xFF8B938E),
                size: isLocked ? 22 : 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _accentFor(ShortPlatform platform) => switch (platform) {
    ShortPlatform.tiktok => const Color(0xFF246A55),
    ShortPlatform.youtubeShorts => const Color(0xFFC44639),
    ShortPlatform.instagramReels => const Color(0xFF9C4A1A),
    ShortPlatform.youtubeLong => const Color(0xFF2F5D8A),
  };

  static IconData _iconFor(ShortPlatform platform) => switch (platform) {
    ShortPlatform.tiktok => Icons.music_note_rounded,
    ShortPlatform.youtubeShorts => Icons.smart_display_rounded,
    ShortPlatform.instagramReels => Icons.movie_filter_outlined,
    ShortPlatform.youtubeLong => Icons.ondemand_video_rounded,
  };
}
