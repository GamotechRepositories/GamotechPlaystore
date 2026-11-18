import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../services/game_service.dart';

class GameWebViewScreen extends StatefulWidget {
  const GameWebViewScreen({super.key, required this.game});

  final Game game;

  @override
  State<GameWebViewScreen> createState() => _GameWebViewScreenState();
}

class _GameWebViewScreenState extends State<GameWebViewScreen> {
  WebViewController? _controller;
  int _progress = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    final uri = widget.game.playUri;
    if (uri == null) {
      _error = 'This game is not available to play yet.';
      return;
    }
    if (kIsWeb ||
        ![
          TargetPlatform.android,
          TargetPlatform.iOS,
          TargetPlatform.macOS,
        ].contains(defaultTargetPlatform)) {
      _error = 'Play this game in the Android or iOS app.';
      return;
    }
    _controller = WebViewController();
    _load(uri);
  }

  Future<void> _load(Uri uri) async {
    try {
      await _controller!.setJavaScriptMode(JavaScriptMode.unrestricted);
      await _controller!.setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final url = Uri.tryParse(request.url);
            return url != null && ['http', 'https'].contains(url.scheme)
                ? NavigationDecision.navigate
                : NavigationDecision.prevent;
          },
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                _error = null;
                _progress = 0;
              });
            }
          },
          onProgress: (value) {
            if (mounted) setState(() => _progress = value);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _progress = 100);
          },
          onWebResourceError: (error) {
            if (mounted && error.isForMainFrame == true) {
              setState(
                () => _error =
                    'Unable to load this game. Check your connection and try again.',
              );
            }
          },
        ),
      );
      await _controller!.loadRequest(uri);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to open this game. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.game.name),
      actions: [
        if (_controller != null)
          IconButton(
            tooltip: 'Reload game',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _error = null;
                _progress = 0;
              });
              _load(widget.game.playUri!);
            },
          ),
      ],
    ),
    body: SafeArea(
      child: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!, textAlign: TextAlign.center),
              ),
            )
          : Column(
              children: [
                if (_progress < 100)
                  LinearProgressIndicator(
                    value: _progress / 100,
                    semanticsLabel: 'Loading game',
                  ),
                if (_controller != null)
                  Expanded(child: WebViewWidget(controller: _controller!)),
              ],
            ),
    ),
  );
}
