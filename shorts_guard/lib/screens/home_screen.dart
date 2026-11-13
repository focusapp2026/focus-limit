import 'dart:async';

import 'package:flutter/material.dart';

import '../app.dart';
import '../models/daily_usage.dart';
import '../models/short_video.dart';
import '../services/daily_limit_store.dart';
import '../widgets/quota_card.dart';
import 'add_video_screen.dart';
import 'video_player_screen.dart'
    if (dart.library.html) 'video_player_screen_web.dart'
    as player;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final DailyLimitStore _store = DailyLimitStore();
  List<ShortVideo> _videos = [];
  DailyUsage _usage = DailyUsage.today();
  bool _isLoading = true;
  String? _loadError;
  Timer? _midnightRefresh;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshData();
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
      _refreshData();
      _scheduleMidnightRefresh();
    }
  }

  void _scheduleMidnightRefresh() {
    _midnightRefresh?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    _midnightRefresh = Timer(
      nextMidnight.difference(now) + const Duration(seconds: 1),
      () async {
        await _refreshData();
        if (mounted) _scheduleMidnightRefresh();
      },
    );
  }

  Future<void> _refreshData() async {
    try {
      final videos = await _store.loadVideos();
      final usage = await _store.loadUsage();
      if (!mounted) return;
      setState(() {
        _videos = videos;
        _usage = usage;
        _loadError = null;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = 'تعذر تحميل بياناتك. أعد فتح التطبيق أو حاول مجددًا.';
        _isLoading = false;
      });
    }
  }

  Future<void> _addVideo() async {
    final video = await Navigator.of(context).push<ShortVideo>(
      MaterialPageRoute(builder: (_) => const AddVideoScreen()),
    );
    if (video == null) return;

    try {
      await _store.addVideo(video);
      await _refreshData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت إضافة الفيديو إلى قائمتك.')),
        );
      }
    } catch (error) {
      _showMessage('تعذر حفظ الفيديو. حاول مرة أخرى.');
    }
  }

  Future<bool> _consumeAdditionalVideo(VideoPlatform platform) async {
    try {
      final allowed = await _store.consume(platform);
      final usage = await _store.loadUsage();
      if (mounted) setState(() => _usage = usage);
      return allowed;
    } catch (error) {
      _showMessage('تعذر تحديث رصيد اليوم.');
      return false;
    }
  }

  Future<void> _startVideo(ShortVideo video) async {
    try {
      final allowed = await _store.consume(video.platform);
      final usage = await _store.loadUsage();
      if (mounted) setState(() => _usage = usage);

      if (!allowed) {
        _showMessage('انتهى رصيد ${video.platform.label} لهذا اليوم.');
        return;
      }
      if (!mounted) return;

      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => player.VideoPlayerScreen(
            video: video,
            onAdditionalVideoStarted: _consumeAdditionalVideo,
          ),
        ),
      );
      await _refreshData();
    } catch (error) {
      _showMessage('تعذر بدء الفيديو. تحقق من اتصال الإنترنت.');
    }
  }

  Future<void> _deleteVideo(ShortVideo video) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الفيديو؟'),
        content: Text('سيُحذف «${video.title}» من قائمتك.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (shouldDelete != true) return;

    try {
      await _store.removeVideo(video.id);
      await _refreshData();
    } catch (error) {
      _showMessage('تعذر حذف الفيديو.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  List<ShortVideo> _videosFor(VideoPlatform platform) => _videos
      .where((video) => video.platform == platform)
      .toList(growable: false);

  Widget _videoSection(VideoPlatform platform) {
    final videos = _videosFor(platform);
    final hasQuota = _usage.remainingFor(platform) > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              platform.label,
              style: const TextStyle(
                color: ShortsGuardApp.ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${videos.length}',
                style: const TextStyle(
                  color: Color(0xFF68736D),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Spacer(),
            if (videos.isNotEmpty)
              Text(
                hasQuota
                    ? '${_usage.remainingFor(platform)} متبقية'
                    : 'اكتمل حد اليوم',
                style: TextStyle(
                  color: hasQuota
                      ? const Color(0xFF68736D)
                      : const Color(0xFF9B443B),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (videos.isEmpty)
          _EmptyVideoList(platform: platform, onAdd: _addVideo)
        else
          ...videos.map(
            (video) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _VideoTile(
                video: video,
                canPlay: hasQuota,
                onPlay: () => _startVideo(video),
                onDelete: () => _deleteVideo(video),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: ShortsGuardApp.forest),
        ),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
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
                      setState(() {
                        _isLoading = true;
                        _loadError = null;
                      });
                      _refreshData();
                    },
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final remainingTotal =
        _usage.remainingFor(VideoPlatform.tiktok) +
        _usage.remainingFor(VideoPlatform.youtube);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: ShortsGuardApp.forest,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 112),
            children: [
              _Header(onAdd: _addVideo),
              const SizedBox(height: 18),
              _WelcomeCard(remainingTotal: remainingTotal),
              const SizedBox(height: 24),
              const Text(
                'رصيد اليوم',
                style: TextStyle(
                  color: ShortsGuardApp.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              QuotaCard(platform: VideoPlatform.tiktok, usage: _usage),
              const SizedBox(height: 10),
              QuotaCard(platform: VideoPlatform.youtube, usage: _usage),
              const SizedBox(height: 28),
              _videoSection(VideoPlatform.tiktok),
              const SizedBox(height: 22),
              _videoSection(VideoPlatform.youtube),
              const SizedBox(height: 20),
              const Text(
                'تُحفظ قائمتك ورصيدك على هذا الجهاز، ويُجدَّد الرصيد عند منتصف الليل.',
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addVideo,
        backgroundColor: ShortsGuardApp.forest,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('إضافة فيديو'),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFF1E5B48),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.spa_outlined, color: Colors.white),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'مساحة',
                style: TextStyle(
                  color: ShortsGuardApp.ink,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'اختر ما يستحق وقتك',
                style: TextStyle(color: Color(0xFF7C867F), fontSize: 12),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: onAdd,
          tooltip: 'إضافة فيديو',
          icon: const Icon(Icons.add_rounded),
        ),
      ],
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.remainingTotal});

  final int remainingTotal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E5B48), Color(0xFF163E35)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -6,
            bottom: -24,
            child: Icon(
              Icons.spa_rounded,
              size: 115,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'مساحة لوقتك',
                  style: TextStyle(
                    color: Color(0xFFE2F4E8),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 17),
              const Text(
                'فيديو أقل.\nوقت أكثر لك.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  height: 1.15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 11),
              Text(
                'حدود واضحة تساعدك تختار متى تتوقف.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Icon(
                    Icons.play_circle_outline_rounded,
                    size: 19,
                    color: Color(0xFFBCE4C7),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'باقي $remainingTotal ${remainingTotal == 1 ? 'فيديو' : 'فيديوهات'} من رصيدك اليوم',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyVideoList extends StatelessWidget {
  const _EmptyVideoList({required this.platform, required this.onAdd});

  final VideoPlatform platform;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7EAE4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bookmark_add_outlined, color: Color(0xFF7A8980)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'أضف رابط فيديو $platform لتشاهده هنا.',
              style: const TextStyle(
                color: Color(0xFF68736D),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
          TextButton(onPressed: onAdd, child: const Text('إضافة')),
        ],
      ),
    );
  }
}

class _VideoTile extends StatelessWidget {
  const _VideoTile({
    required this.video,
    required this.canPlay,
    required this.onPlay,
    required this.onDelete,
  });

  final ShortVideo video;
  final bool canPlay;
  final VoidCallback onPlay;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final accent = video.platform == VideoPlatform.tiktok
        ? const Color(0xFF246A55)
        : const Color(0xFFC44639);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7EAE4)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.play_arrow_rounded, color: accent, size: 27),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ShortsGuardApp.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  video.platform.label,
                  style: TextStyle(color: accent, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            tooltip: 'حذف الفيديو',
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFF8B938E),
              size: 21,
            ),
          ),
          const SizedBox(width: 2),
          FilledButton(
            onPressed: canPlay ? onPlay : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              backgroundColor: accent,
              disabledBackgroundColor: const Color(0xFFE8EBE7),
              disabledForegroundColor: const Color(0xFF828A84),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text(canPlay ? 'شاهد' : 'غدًا'),
          ),
        ],
      ),
    );
  }
}
