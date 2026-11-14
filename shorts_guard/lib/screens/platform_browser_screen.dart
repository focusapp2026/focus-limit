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
      'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Mobile Safari/537.36';
  static final _blankPage = Uri.parse('about:blank');

  final DailyLimitStore _store = DailyLimitStore();
  late final WebViewController _controller;
  Future<void> _pendingUpdate = Future.value();
  DailyUsage? _usage;
  bool _isLocked = false;
  bool _isLoading = true;
  String? _loadError;

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
          onUrlChange: (_) => _injectTrackerOnContentPage(),
          onWebResourceError: (error) {
            if (error.isForMainFrame == true && mounted) {
              setState(() {
                _isLoading = false;
                _loadError =
                    'تعذر فتح ${widget.platform.label}. تحقق من اتصال الإنترنت.';
              });
            }
          },
          onNavigationRequest: (request) {
            if (_isExternalAppLink(request.url)) {
              // Links like "Open TikTok" try to leave the WebView for the
              // native app; block them and stop the endless loading bar.
              if (mounted) setState(() => _isLoading = false);
              return NavigationDecision.prevent;
            }
            return _allowNavigation(request)
                ? NavigationDecision.navigate
                : NavigationDecision.prevent;
          },
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

  // Dismisses "Open TikTok / Open Instagram / Get the full app experience"
  // prompts by pressing "Not now" or the close (X) button, then hides them.
  static const _popupDismissScript = r'''
(function () {
  if (window.__pymPopupGuard) return;
  window.__pymPopupGuard = true;

  var promptText = /(get the full app experience|open tiktok|open instagram|open app|open the app|use the app|open in app|continue in app|افتح التطبيق|فتح التطبيق|استخدم التطبيق)/i;
  var dismissText = /^(not now|no thanks|maybe later|continue in browser|stay in browser|cancel|close|ليس الآن|لاحقًا|لاحقا|إلغاء|إغلاق|المتابعة في المتصفح)$/i;
  var closeLabel = /(close|dismiss|not now|إغلاق|ليس الآن)/i;

  function textOf(el) {
    return (el.innerText || el.textContent || '').trim();
  }

  function isOverlay(el) {
    if (!el || el === document.body || el === document.documentElement) return false;
    var role = el.getAttribute && el.getAttribute('role');
    if (role === 'dialog' || role === 'alertdialog' || el.tagName === 'DIALOG') return true;
    var pos = window.getComputedStyle(el).position;
    return pos === 'fixed' || pos === 'sticky';
  }

  function findOverlay(el) {
    var node = el;
    for (var depth = 0; node && depth < 12; depth++) {
      if (isOverlay(node)) return node;
      node = node.parentElement;
    }
    return null;
  }

  function pressDismiss(container) {
    var buttons = container.querySelectorAll('button, [role="button"], a, div[tabindex], span[tabindex]');
    for (var i = 0; i < buttons.length; i++) {
      var b = buttons[i];
      var t = textOf(b);
      var label = (b.getAttribute('aria-label') || '') + ' ' + (b.getAttribute('title') || '');
      if ((t && dismissText.test(t)) || closeLabel.test(label) || t === '×' || t === '✕' || t === 'X') {
        try { b.click(); return true; } catch (e) {}
      }
    }
    return false;
  }

  function sweep() {
    var candidates = document.querySelectorAll(
      '[role="dialog"], [role="alertdialog"], dialog, button, a, div, section'
    );
    for (var i = 0; i < candidates.length; i++) {
      var el = candidates[i];
      if (el.__pymHandled) continue;
      var t = textOf(el);
      if (!t || t.length > 300 || !promptText.test(t)) continue;
      var overlay = findOverlay(el);
      if (!overlay || overlay.__pymHandled) continue;
      // Never hide something that covers the whole page content.
      if (textOf(overlay).length > 600) continue;
      overlay.__pymHandled = true;
      el.__pymHandled = true;
      pressDismiss(overlay);
      overlay.style.setProperty('display', 'none', 'important');
    }
    // Restore scrolling if a modal locked the page.
    if (document.body && document.body.style.overflow === 'hidden') {
      document.body.style.overflow = '';
    }
    if (document.documentElement && document.documentElement.style.overflow === 'hidden') {
      document.documentElement.style.overflow = '';
    }
  }

  setInterval(sweep, 800);
  sweep();
})();
''';

  static bool _isExternalAppLink(String url) {
    final lower = url.toLowerCase();
    return lower.startsWith('intent://') ||
        lower.startsWith('intent:') ||
        lower.startsWith('tiktok://') ||
        lower.startsWith('snssdk') ||
        lower.startsWith('instagram://') ||
        lower.startsWith('market://');
  }

  Uri get _loginUri => switch (widget.platform) {
    ShortPlatform.tiktok => Uri.parse('https://tiktok.com'),
    ShortPlatform.instagramReels => Uri.parse('https://instagram.com'),
    ShortPlatform.youtubeShorts ||
    ShortPlatform.youtubeLong => Uri.parse('https://google.com'),
  };

  Future<void> _openLoginPage() async {
    if (_isLocked) return;
    setState(() {
      _loadError = null;
      _isLoading = true;
    });
    await _controller.loadRequest(_loginUri);
  }

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
        widget.platform.allowsNavigation(uri);
  }

  Future<void> _loadUsage() async {
    try {
      final usage = await _store.loadUsage();
      if (!mounted) return;
      setState(() => _usage = usage);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadError = 'تعذر تحميل عدّاد اليوم. حاول مجددًا.');
    }
  }

  Future<void> _handlePageFinished() async {
    if (!mounted || _isLocked) return;
    setState(() {
      _isLoading = false;
      _loadError = null;
    });
    await _injectTrackerOnContentPage();
  }

  Future<void> _injectTrackerOnContentPage() async {
    if (_isLocked) return;
    await _controller.runJavaScript(_popupDismissScript);
    final url = await _controller.currentUrl();
    final uri = url == null ? null : Uri.tryParse(url);
    if (uri != null && widget.platform.isAuthPage(uri)) return;
    await _controller.runJavaScript(_trackerScript);
  }

  void _handleViewDetected(JavaScriptMessage message) {
    if (_isLocked) return;
    final decoded = jsonDecode(message.message);
    if (decoded is! Map<String, dynamic>) return;

    final viewId = decoded['id'];
    final pageUrl = decoded['url'];
    final pageUri = pageUrl is String ? Uri.tryParse(pageUrl) : null;
    if (viewId is! String || viewId.trim().isEmpty || pageUri == null) return;
    if (!widget.platform.countsPage(pageUri)) return;

    final trimmedId = viewId.trim();
    _pendingUpdate = _pendingUpdate.then((_) => _registerView(trimmedId));
  }

  Future<void> _registerView(String viewId) async {
    if (_isLocked) return;
    try {
      final result = await _store.recordView(widget.platform, viewId);
      if (!mounted) return;
      if (result.outcome == ViewOutcome.limitReached) {
        _isLocked = true;
        await _controller.loadRequest(_blankPage);
      }
      if (!mounted) return;
      setState(() => _usage = result.usage);
    } catch (_) {
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('تعذر حفظ عدّاد اليوم لهذا الفيديو.')),
        );
    }
  }

  Future<void> _handleDayReset() async {
    if (!mounted) return;
    setState(() {
      _isLocked = false;
      _isLoading = true;
      _loadError = null;
    });
    await _loadUsage();
    if (mounted) await _openStartPage();
  }

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

    return Scaffold(
      backgroundColor: const Color(0xFF101412),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101412),
        foregroundColor: Colors.white,
        title: Text(widget.platform.label),
        actions: [
          if (!_isLocked)
            IconButton(
              tooltip: 'تسجيل الدخول',
              iconSize: 20,
              icon: const Icon(Icons.login_rounded),
              onPressed: _openLoginPage,
            ),
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
          if (!_isLocked)
            Positioned.fill(child: WebViewWidget(controller: _controller)),
          if (_isLoading && !_isLocked)
            const Align(
              alignment: Alignment.topCenter,
              child: LinearProgressIndicator(
                color: Color(0xFF9AD5B4),
                backgroundColor: Color(0xFF26332D),
              ),
            ),
          if (_loadError != null && !_isLocked)
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
          if (_isLocked)
            Positioned.fill(
              child: LockOverlay(
                platform: widget.platform,
                onReset: _handleDayReset,
              ),
            ),
        ],
      ),
    );
  }
}
