import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/daily_usage.dart';
import '../models/short_platform.dart';
import '../services/daily_limit_store.dart';
import '../widgets/lock_overlay.dart';

class PlatformBrowserScreen extends StatefulWidget {
  const PlatformBrowserScreen({required this.platform, super.key});

  final ShortPlatform platform;

  @override
  State<PlatformBrowserScreen> createState() => _PlatformBrowserScreenState();
}

class _PlatformBrowserScreenState extends State<PlatformBrowserScreen> {
  static const _trackerChannel = 'ShortsTracker';
  static const _pauseMediaScript =
      "document.querySelectorAll('video').forEach(function (v) { v.pause(); });";

  final DailyLimitStore _store = DailyLimitStore();
  late final WebViewController _controller;
  Future<void> _pendingUpdate = Future.value();
  DailyUsage? _usage;
  bool _isLoading = true;
  String? _loadError;

  bool get _isLocked {
    final usage = _usage;
    return usage != null && usage.remainingFor(widget.platform) == 0;
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF101412))
      ..addJavaScriptChannel(
        _trackerChannel,
        onMessageReceived: _handleViewDetected,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) => _handlePageFinished(),
          onWebResourceError: (error) {
            if (error.isForMainFrame == true && mounted) {
              setState(() {
                _isLoading = false;
                _loadError =
                    'تعذر فتح ${widget.platform.label}. تحقق من اتصال الإنترنت.';
              });
            }
          },
          onNavigationRequest: (request) =>
              _allowNavigation(request)
              ? NavigationDecision.navigate
              : NavigationDecision.prevent,
        ),
      )
      ..loadRequest(widget.platform.startUri);
    _pendingUpdate = _loadUsage();
  }

  String get _trackerScript =>
      '''
(function () {
  if (window.__pymTracker) return;
  window.__pymTracker = true;
  var pattern = /${widget.platform.viewIdPattern}/;
  var lastId = null;

  function playingSource() {
    var videos = document.querySelectorAll('video');
    for (var i = 0; i < videos.length; i++) {
      if (!videos[i].paused && videos[i].currentSrc) return videos[i].currentSrc;
    }
    return null;
  }

  function check() {
    var match = location.pathname.match(pattern);
    var id = match ? match[1] : playingSource();
    if (id && id !== lastId) {
      lastId = id;
      ${_trackerChannel}.postMessage(id);
    }
  }

  setInterval(check, 500);
  check();
})();
''';

  bool _allowNavigation(NavigationRequest request) {
    if (_isLocked) return false;
    if (!request.isMainFrame) return true;

    final host = Uri.tryParse(request.url)?.host.toLowerCase() ?? '';
    return widget.platform.allowedHosts.any(
      (domain) => host == domain || host.endsWith('.$domain'),
    );
  }

  Future<void> _loadUsage() async {
    try {
      final usage = await _store.loadUsage();
      if (!mounted) return;
      setState(() => _usage = usage);
      if (_isLocked) await _pauseMedia();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadError = 'تعذر تحميل عدّاد اليوم. حاول مجددًا.');
    }
  }

  Future<void> _handlePageFinished() async {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _loadError = null;
    });
    await _controller.runJavaScript(_trackerScript);
    if (_isLocked) await _pauseMedia();
  }

  void _handleViewDetected(JavaScriptMessage message) {
    final viewId = message.message.trim();
    if (viewId.isEmpty) return;
    _pendingUpdate = _pendingUpdate.then((_) => _recordView(viewId));
  }

  Future<void> _recordView(String viewId) async {
    try {
      final usage = await _store.recordView(widget.platform, viewId);
      if (!mounted) return;
      setState(() => _usage = usage);
      if (_isLocked) await _pauseMedia();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('تعذر حفظ عدّاد اليوم لهذا الفيديو.')),
        );
    }
  }

  Future<void> _pauseMedia() => _controller.runJavaScript(_pauseMediaScript);

  void _retry() {
    setState(() {
      _loadError = null;
      _isLoading = true;
    });
    _pendingUpdate = _loadUsage();
    _controller.loadRequest(widget.platform.startUri);
  }

  @override
  Widget build(BuildContext context) {
    final usage = _usage;
    final isLocked = _isLocked;

    return Scaffold(
      backgroundColor: const Color(0xFF101412),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101412),
        foregroundColor: Colors.white,
        title: Text(widget.platform.label),
        actions: [
          if (usage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'باقي ${usage.remainingFor(widget.platform)} من ${widget.platform.dailyLimit}',
                  style: const TextStyle(
                    color: Color(0xFF9AD5B4),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(child: WebViewWidget(controller: _controller)),
          if (_isLoading && !isLocked)
            const Align(
              alignment: Alignment.topCenter,
              child: LinearProgressIndicator(
                color: Color(0xFF9AD5B4),
                backgroundColor: Color(0xFF26332D),
              ),
            ),
          if (_loadError != null && !isLocked)
            ColoredBox(
              color: const Color(0xFF101412),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.wifi_off_rounded,
                        color: Color(0xFF9AD5B4),
                        size: 42,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _loadError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 18),
                      OutlinedButton.icon(
                        onPressed: _retry,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (isLocked)
            Positioned.fill(
              child: LockOverlay(
                platform: widget.platform,
                onReset: () => _loadUsage(),
              ),
            ),
        ],
      ),
    );
  }
}
