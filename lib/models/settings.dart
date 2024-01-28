import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum MyThemeModes {
  light('Light', 'light'),
  dark('Dark', 'dark'),
  system('System', 'system');

  const MyThemeModes(this.label, this.value);
  final String label;
  final String value;
}

class Settings extends Equatable {
  final bool loadImages;
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
        return ThemeMode.system;
      case MyThemeModes.dark:
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Settings copyWith(
      {bool? loadImages,
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
