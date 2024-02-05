import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum MyThemeModes {
  light('light'),
  dark('dark'),
  system('system');

  const MyThemeModes(this.value);
  final String value;
}

enum LoadImages {
  always('always'),
  wifi('wifi'),
  never('never');

  const LoadImages(this.value);
  final String value;
}

class Settings extends Equatable {
  final LoadImages loadImages;
  final bool condensed;
  final int? imageWidth;
  final MyThemeModes themeMode;

  const Settings(
      {required this.loadImages,
      required this.condensed,
      required this.imageWidth,
      required this.themeMode});

  ThemeMode getThemeMode() {
    switch (themeMode) {
      case MyThemeModes.light:
        return ThemeMode.light;
      case MyThemeModes.dark:
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Settings copyWith(
      {LoadImages? loadImages,
      bool? condensed,
      int? imageWidth,
      MyThemeModes? themeMode,
      bool useImageWidthParameter = false}) {
    return Settings(
        themeMode: themeMode ?? this.themeMode,
        loadImages: loadImages ?? this.loadImages,
        condensed: condensed ?? this.condensed,
        imageWidth: useImageWidthParameter
            ? imageWidth
            : (imageWidth ?? this.imageWidth));
  }

  @override
  List<Object?> get props => [loadImages, condensed, imageWidth, themeMode];
}
