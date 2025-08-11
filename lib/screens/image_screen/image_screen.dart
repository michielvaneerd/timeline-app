import 'package:flutter/material.dart';

class ImageScreen extends StatelessWidget {
  final Image image;
  final String tag;
  const ImageScreen({
    super.key,
    required this.image,
    required this.tag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(), body: Hero(tag: tag, child: Center(child: image)));
  }
}
