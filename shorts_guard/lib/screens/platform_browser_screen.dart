import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

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
  static const _userAgent =
      'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36';
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
      );
    _pendingUpdate = _loadUsage();
    _openStartPage();
  }

  String get _trackerScript =>
      '''
(function () {
  if (window.__pymTracker) return;
  window.__pymTracker = true;
  var pattern = /${widget.platform.viewIdPattern}/;
  var detectsMedia = ${widget.platform.detectsPlayingMedia};
  var lastId = null;

  function playingSource() {
    var videos = document.querySelectorAll('video');
    for (var i = 0; i < videos.length; i++) {
      if (!videos[i].paused && videos[i].currentSrc) return videos[i].currentSrc;
    }
    return null;
  }

  function check() {
    var match = location.href.match(pattern);
    var id = match ? match[1] : (detectsMedia ? playingSource() : null);
    if (id && id !== lastId) {
      lastId = id;
      ${_trackerChannel}.postMessage(JSON.stringify({ id: id, url: location.href }));
    }
  }

  setInterval(check, 500);
  check();
})();
''';

  Future<void> _openStartPage() async {
    await _controller.setUserAgent(_userAgent);
    final platformController = _controller.platform;
    final cookieManager = WebViewCookieManager().platform;
    if (platformController is AndroidWebViewController &&
        cookieManager is AndroidWebViewCookieManager) {
      await cookieManager.setAcceptThirdPartyCookies(platformController, true);
    }
    await _controller.loadRequest(widget.platform.startUri);
  }

  bool _allowNavigation(NavigationRequest request) {
    if (_isLocked) return false;
    if (!request.isMainFrame) return true;

    final uri = Uri.tryParse(request.url);
    return uri != null &&
        uri.scheme == 'https' &&
        hostMatches(uri, widget.platform.allowedHosts);
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
    final decoded = jsonDecode(message.message);
    if (decoded is! Map<String, dynamic>) return;

    final viewId = decoded['id'];
    final pageUrl = decoded['url'];
    final pageUri = pageUrl is String ? Uri.tryParse(pageUrl) : null;
    if (viewId is! String || viewId.trim().isEmpty || pageUri == null) return;
    if (!widget.platform.countsPage(pageUri)) return;

    final trimmedId = viewId.trim();
    _pendingUpdate = _pendingUpdate.then((_) => _recordView(trimmedId));
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
    _openStartPage();
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
