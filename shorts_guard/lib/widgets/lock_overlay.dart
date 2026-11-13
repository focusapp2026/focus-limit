import 'package:flutter/material.dart';

import '../models/short_platform.dart';
import 'lock_countdown.dart';

class LockOverlay extends StatelessWidget {
  const LockOverlay({required this.platform, required this.onReset, super.key});

  final ShortPlatform platform;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      child: ColoredBox(
        color: const Color(0xFF101412),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_rounded,
                  color: Color(0xFF9AD5B4),
                  size: 56,
                ),
                const SizedBox(height: 18),
                Text(
                  'تم إقفال ${platform.label} لهذا اليوم',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'وصلت إلى حدك اليومي (${platform.dailyLimit} فيديوهات). '
                  'يُفتح الحد مجددًا غدًا.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFD5DED8),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'يُفتح بعد',
                  style: TextStyle(
                    color: Color(0xFF9AD5B4),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                LockCountdown(
                  onReset: onReset,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 28),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF3A4A43)),
                    minimumSize: const Size(0, 48),
                  ),
                  child: const Text('العودة إلى PYM'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
