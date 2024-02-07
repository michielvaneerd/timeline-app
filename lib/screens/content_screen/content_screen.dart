import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:timeline/models/settings.dart';
import 'package:timeline/models/timeline.dart';
import 'package:timeline/models/timeline_host.dart';
import 'package:timeline/models/timeline_item.dart';
import 'package:timeline/utils.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ContentScreen extends StatefulWidget {
  final Timeline timeline;
  final TimelineHost timelineHost;
  final TimelineItem timelineItem;
  final Settings settings;
  final Color onSurfaceColor;
  final Color surfaceColor;
  const ContentScreen(
      {super.key,
      required this.timelineHost,
      required this.timeline,
      required this.settings,
      required this.onSurfaceColor,
      required this.surfaceColor,
      required this.timelineItem});

  @override
  State<ContentScreen> createState() => _ContentScreenState();
}

class _ContentScreenState extends State<ContentScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    final fgColor = Utils.getHex(widget.onSurfaceColor);
    final bgColor = Utils.getHex(widget.surfaceColor);
    if (kDebugMode) {
      _controller = WebViewController()
        ..clearCache()
        ..loadRequest(Uri.parse(
            '${widget.timelineHost.host}/?p=${widget.timelineItem.postId}&theme=${widget.settings.themeMode.value}&fg=$fgColor&bg=$bgColor'));
    } else {
      _controller = WebViewController()
        ..loadRequest(Uri.parse(
            '${widget.timelineHost.host}/?p=${widget.timelineItem.postId}&theme=${widget.settings.themeMode.value}&fg=$fgColor&bg=$bgColor'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            '${widget.timeline.name} / ${widget.timelineItem.year} / ${widget.timelineItem.title}'),
      ),
      body: WebViewWidget(
        controller: _controller,
      ),
    );
  }
}
