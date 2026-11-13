import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/short_video.dart';

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({
    required this.video,
    required this.onAdditionalVideoStarted,
    super.key,
  });

  final ShortVideo video;
  final Future<bool> Function(VideoPlatform platform) onAdditionalVideoStarted;

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final WebViewController _controller;
  final Set<String> _reportedVideoIds = {};
  bool _isLoading = true;
  bool _showQuotaMessage = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _reportedVideoIds.add(widget.video.videoId);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF101412))
      ..addJavaScriptChannel(
        'VideoTracker',
        onMessageReceived: _handleVideoStarted,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _loadError = null;
              });
            }
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == true && mounted) {
              setState(() {
                _isLoading = false;
                _loadError =
                    'تعذر تحميل الفيديو. تحقق من اتصال الإنترنت والرابط.';
              });
            }
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null) return NavigationDecision.prevent;
            if (_isAllowedPlayerHost(uri.host.toLowerCase())) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
        ),
      );

    if (widget.video.platform == VideoPlatform.youtube) {
      _controller.loadHtmlString(
        _youtubePlayerHtml(widget.video.videoId),
        baseUrl: Uri.https('www.youtube.com').toString(),
      );
    } else {
      _controller.loadHtmlString(
        _tiktokPlayerHtml(widget.video.playerUri),
        baseUrl: Uri.https('www.tiktok.com').toString(),
      );
    }
  }

  bool _isAllowedPlayerHost(String host) {
    const allowedDomains = [
      'youtube.com',
      'youtube-nocookie.com',
      'ytimg.com',
      'googlevideo.com',
      'google.com',
      'tiktok.com',
      'tiktokcdn.com',
      'tiktokv.com',
    ];
    return allowedDomains.any(
      (domain) => host == domain || host.endsWith('.$domain'),
    );
  }

  Future<void> _handleVideoStarted(JavaScriptMessage message) async {
    final videoId = message.message.trim();
    if (videoId.isEmpty || !_reportedVideoIds.add(videoId)) return;

    final allowed = await widget.onAdditionalVideoStarted(
      widget.video.platform,
    );
    if (!mounted) return;

    if (!allowed) {
      setState(() => _showQuotaMessage = true);
      try {
        await _controller.runJavaScript('player && player.stopVideo();');
      } catch (_) {
        // The overlay below still blocks the player if the embedded player
        // does not expose its JavaScript object.
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم احتساب فيديو إضافي من رصيد ${widget.video.platform.label}.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _youtubePlayerHtml(String videoId) =>
      '''
<!doctype html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
  <style>
    html, body, #player { width: 100%; height: 100%; margin: 0; background: #101412; }
  </style>
</head>
<body>
  <div id="player"></div>
  <script>
    let player;
    let lastReportedId = null;
    const tag = document.createElement('script');
    tag.src = 'https://www.youtube.com/iframe_api';
    document.head.appendChild(tag);
    function onYouTubeIframeAPIReady() {
      player = new YT.Player('player', {
        videoId: '$videoId',
        playerVars: {
          autoplay: 1,
          playsinline: 1,
          rel: 0,
          origin: 'https://www.youtube.com'
        },
        events: { onStateChange: onPlayerStateChange }
      });
    }
    function onPlayerStateChange(event) {
      if (event.data !== YT.PlayerState.PLAYING) return;
      const currentId = event.target.getVideoData().video_id;
      if (currentId && currentId !== lastReportedId) {
        lastReportedId = currentId;
        VideoTracker.postMessage(currentId);
      }
    }
  </script>
</body>
</html>
''';

  String _tiktokPlayerHtml(Uri playerUri) =>
      '''
<!doctype html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
  <style>
    html, body, iframe { width: 100%; height: 100%; margin: 0; border: 0; background: #101412; }
  </style>
</head>
<body>
  <iframe
    src="${playerUri.toString()}"
    allow="autoplay; fullscreen; encrypted-media"
    allowfullscreen
    title="TikTok video">
  </iframe>
</body>
</html>
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101412),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101412),
        foregroundColor: Colors.white,
        title: Text(
          widget.video.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: WebViewWidget(controller: _controller),
                  ),
                  if (_isLoading)
                    const Align(
                      alignment: Alignment.topCenter,
                      child: LinearProgressIndicator(
                        color: Color(0xFF9AD5B4),
                        backgroundColor: Color(0xFF26332D),
                      ),
                    ),
                  if (_loadError != null)
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
                                onPressed: () {
                                  setState(() {
                                    _loadError = null;
                                    _isLoading = true;
                                  });
                                  if (widget.video.platform ==
                                      VideoPlatform.youtube) {
                                    _controller.loadHtmlString(
                                      _youtubePlayerHtml(widget.video.videoId),
                                      baseUrl: Uri.https(
                                        'www.youtube.com',
                                      ).toString(),
                                    );
                                  } else {
                                    _controller.loadHtmlString(
                                      _tiktokPlayerHtml(widget.video.playerUri),
                                      baseUrl: Uri.https(
                                        'www.tiktok.com',
                                      ).toString(),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('إعادة المحاولة'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (_showQuotaMessage)
                    Positioned.fill(
                      child: ColoredBox(
                        color: const Color(0xF218231F),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(26),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle_outline_rounded,
                                  color: Color(0xFF9AD5B4),
                                  size: 52,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'انتهى رصيد اليوم',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 23,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'لن يبدأ فيديو آخر من ${widget.video.platform.label} حتى الغد.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFFD5DED8),
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 22),
                                FilledButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('العودة'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 13, 18, 16),
              color: const Color(0xFF18231F),
              child: const Text(
                'احتُسب هذا الفيديو من رصيدك عند فتحه. المشاهدة داخل مساحة فقط.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFFD5DED8), fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
