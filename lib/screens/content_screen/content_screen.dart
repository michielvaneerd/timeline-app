import 'package:flutter/material.dart';
import 'package:timeline/models/timeline.dart';
import 'package:timeline/models/timeline_host.dart';
import 'package:timeline/models/timeline_item.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ContentScreen extends StatefulWidget {
  final Timeline timeline;
  final TimelineHost timelineHost;
  final TimelineItem timelineItem;
  const ContentScreen(
      {super.key,
      required this.timelineHost,
      required this.timeline,
      required this.timelineItem});

  @override
  State<ContentScreen> createState() => _ContentScreenState();
}

class _ContentScreenState extends State<ContentScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..loadRequest(Uri.parse(
          '${widget.timelineHost.host}/?p=${widget.timelineItem.postId}'));
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
