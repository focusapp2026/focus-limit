import 'package:flutter/material.dart';

import '../models/daily_usage.dart';
import '../models/short_video.dart';

class QuotaCard extends StatelessWidget {
  const QuotaCard({required this.platform, required this.usage, super.key});

  final VideoPlatform platform;
  final DailyUsage usage;

  @override
  Widget build(BuildContext context) {
    final count = usage.countFor(platform);
    final remaining = usage.remainingFor(platform);
    final isTikTok = platform == VideoPlatform.tiktok;
    final accent = isTikTok ? const Color(0xFF246A55) : const Color(0xFFC44639);
    final background = isTikTok
        ? const Color(0xFFE7F0EA)
        : const Color(0xFFF8EAE5);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7EAE4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isTikTok ? Icons.music_note_rounded : Icons.smart_display,
                  color: accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  platform.label,
                  style: const TextStyle(
                    color: Color(0xFF18231F),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$count / ${platform.dailyLimit}',
                style: TextStyle(
                  color: accent,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: count / platform.dailyLimit,
              minHeight: 8,
              backgroundColor: background,
              color: accent,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            remaining == 0
                ? 'انتهى رصيدك اليوم. يعود غدًا.'
                : 'باقي لك $remaining ${remaining == 1 ? 'فيديو' : 'فيديوهات'} اليوم',
            style: TextStyle(
              color: remaining == 0
                  ? const Color(0xFF9B443B)
                  : const Color(0xFF68736D),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
