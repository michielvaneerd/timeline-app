import 'package:flutter/material.dart';

class ImageScreen extends StatelessWidget {
  final String url;
  const ImageScreen({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(), body: Image.network(url));
  }
}
