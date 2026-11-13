import 'dart:async';

import 'package:flutter/material.dart';

import '../app.dart';
import '../models/daily_usage.dart';
import '../models/short_platform.dart';
import '../services/daily_limit_store.dart';
import '../widgets/platform_card.dart';
import 'platform_browser_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final DailyLimitStore _store = DailyLimitStore();
  DailyUsage? _usage;
  String? _loadError;
  Timer? _midnightRefresh;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshUsage();
    _scheduleMidnightRefresh();
  }

  @override
  void dispose() {
    _midnightRefresh?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshUsage();
      _scheduleMidnightRefresh();
    }
  }

  void _scheduleMidnightRefresh() {
    _midnightRefresh?.cancel();
    _midnightRefresh = Timer(
      DailyUsage.timeUntilReset() + const Duration(seconds: 1),
      () async {
        await _refreshUsage();
        if (mounted) _scheduleMidnightRefresh();
      },
    );
  }

  Future<void> _refreshUsage() async {
    try {
      final usage = await _store.loadUsage();
      if (!mounted) return;
      setState(() {
        _usage = usage;
        _loadError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'تعذر تحميل بياناتك. حاول مجددًا.';
      });
    }
  }

  Future<void> _openPlatform(ShortPlatform platform) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => PlatformBrowserScreen(platform: platform)),
    );
    await _refreshUsage();
  }

  @override
  Widget build(BuildContext context) {
    final usage = _usage;

    if (usage == null) {
      return Scaffold(
        body: Center(
          child: _loadError == null
              ? const CircularProgressIndicator(color: ShortsGuardApp.forest)
              : Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Color(0xFF9B443B),
                        size: 44,
                      ),
                      const SizedBox(height: 14),
                      Text(_loadError!, textAlign: TextAlign.center),
                      const SizedBox(height: 18),
                      FilledButton(
                        onPressed: () {
                          setState(() => _loadError = null);
                          _refreshUsage();
                        },
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshUsage,
          color: ShortsGuardApp.forest,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            children: [
              const _Header(),
              const SizedBox(height: 28),
              const Text(
                'اختر منصة لتبدأ المشاهدة',
                style: TextStyle(
                  color: ShortsGuardApp.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'كل فيديو تمرّره يُحتسب تلقائيًا من حد اليوم.',
                style: TextStyle(color: Color(0xFF68736D), height: 1.5),
              ),
              const SizedBox(height: 20),
              for (final platform in ShortPlatform.values) ...[
                PlatformCard(
                  platform: platform,
                  usage: usage,
                  onOpen: () => _openPlatform(platform),
                  onReset: _refreshUsage,
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 12),
              const Text(
                'تُحفظ أرقامك على هذا الجهاز، ويتجدد الحد عند منتصف الليل.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF7C867F),
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: ShortsGuardApp.forest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.spa_outlined, color: Colors.white),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'PYM',
            style: TextStyle(
              color: ShortsGuardApp.ink,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}
