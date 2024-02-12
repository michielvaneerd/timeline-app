import 'dart:convert' as convert;
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/material.dart';

// https://medium.com/@pnkajvirat/streambuilder-in-flutter-85359f9469df
// https://dev.to/iiits-iota/using-stream-builder-in-flutter-3hkc

class MyImageWithCache extends StatefulWidget {
  const MyImageWithCache(
      {super.key,
      required this.uri,
      required this.width,
      required this.height,
      required this.dirPath,
      required this.cacheOnly,
      required this.pixelRatio});
  final String uri;
  final double width;
  final double height;
  final double pixelRatio;
  final String dirPath;
  final bool cacheOnly;

  @override
  State<MyImageWithCache> createState() => _MyImageWithCacheState();
}

class _MyImageWithCacheState extends State<MyImageWithCache> {
  late Future<Widget> _data;

  Future<Widget> _getImage() async {
    // Dus identieke URLs genereren identieke md5s en dat is goed.
    final hash = crypto.md5.convert(convert.utf8.encode(widget.uri)).toString();
    final path = '${widget.dirPath}/img-$hash';
    final file = File(path);
    if (await file.exists()) {
      return Image.file(
        file,
        cacheWidth: (widget.width * widget.pixelRatio).toInt(),
        cacheHeight: (widget.height * widget.pixelRatio).toInt(),
        width: widget.width,
        height: widget.height,
      );
    } else {
      if (widget.cacheOnly) {
        return Placeholder(
          fallbackWidth: widget.width,
          fallbackHeight: widget.height,
        );
      } else {
        try {
          final response = await http.get(Uri.parse(widget.uri));
          final bytes = response.bodyBytes;
          await file.writeAsBytes(bytes);
          return Image.memory(
            bytes,
            cacheWidth: (widget.width * widget.pixelRatio).toInt(),
            cacheHeight: (widget.height * widget.pixelRatio).toInt(),
            width: widget.width,
            height: widget.height,
          );
        } catch (ex) {
          return Placeholder(
            child: Text(ex.toString()),
          );
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _data = _getImage();
  }

  @override
  void didUpdateWidget(MyImageWithCache oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uri != widget.uri) {
      setState(() {
        _data = _getImage();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return snapshot.data!;
        } else {
          return Opacity(
            opacity: 0,
            child: Placeholder(
              fallbackWidth: widget.width,
              fallbackHeight: widget.height,
            ),
          );
        }
      },
    );
  }
}
