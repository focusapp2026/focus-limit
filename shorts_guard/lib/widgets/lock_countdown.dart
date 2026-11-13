import 'dart:async';

import 'package:flutter/material.dart';

import '../models/daily_usage.dart';

class LockCountdown extends StatefulWidget {
  const LockCountdown({required this.onReset, this.style, super.key});

  final VoidCallback onReset;
  final TextStyle? style;

  @override
  State<LockCountdown> createState() => _LockCountdownState();
}

class _LockCountdownState extends State<LockCountdown> {
  final String _dayKey = DailyUsage.todayKey();
  late Duration _remaining = DailyUsage.timeUntilReset();
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), _tick);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _tick(Timer timer) {
    if (DailyUsage.todayKey() != _dayKey) {
      timer.cancel();
      widget.onReset();
      return;
    }
    setState(() => _remaining = DailyUsage.timeUntilReset());
  }

  String _format(Duration duration) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(duration.inHours)}:'
        '${two(duration.inMinutes.remainder(60))}:'
        '${two(duration.inSeconds.remainder(60))}';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _format(_remaining),
      textDirection: TextDirection.ltr,
      style: widget.style,
    );
  }
}
