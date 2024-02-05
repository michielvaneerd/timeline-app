import 'dart:convert' as convert;
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

// https://medium.com/@pnkajvirat/streambuilder-in-flutter-85359f9469df
// https://dev.to/iiits-iota/using-stream-builder-in-flutter-3hkc

class MyImageWithCache extends StatefulWidget {
  const MyImageWithCache(
      {super.key,
      required this.uri,
      required this.width,
      required this.height,
      required this.pixelRatio});
  final String uri;
  final double width;
  final double height;
  final double pixelRatio;

  @override
  State<MyImageWithCache> createState() => _MyImageWithCacheState();
}

class _MyImageWithCacheState extends State<MyImageWithCache> {
  late Future<Widget> _data;

  Future<Widget> _getImage() async {
    // Dus identieke URLs genereren identieke md5s en dat is goed.
    final hash = crypto.md5.convert(convert.utf8.encode(widget.uri)).toString();
    final dir = await path_provider.getTemporaryDirectory();
    final path = '${dir.path}/img-$hash';
    final file = File(path);
    if (await file.exists()) {
      print('Image ${widget.uri} exists!');
      return Image.file(
        file,
        cacheWidth: (widget.width * widget.pixelRatio).toInt(),
        cacheHeight: (widget.height * widget.pixelRatio).toInt(),
        width: widget.width,
        height: widget.height,
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

  @override
  void initState() {
    super.initState();
    _data = _getImage();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return snapshot.data!;
        } else {
          return Placeholder(
            fallbackWidth: widget.width,
            fallbackHeight: widget.height,
          );
        }
      },
    );
  }
}
