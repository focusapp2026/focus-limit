import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/short_video.dart';

/// Browser-only player used by the Replit preview.
///
/// Native Android and iOS builds use [VideoPlayerScreen] instead, which
/// monitors additional YouTube videos started inside the embedded player.
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

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()..loadRequest(widget.video.playerUri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.video.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: WebViewWidget(controller: _controller)),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF18231F),
              child: const Text(
                'تُحتسب مشاهدة الفيديو عند فتحه في المعاينة.',
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
