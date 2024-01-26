import 'package:equatable/equatable.dart';

class Settings extends Equatable {
  final bool loadImages;
  final bool condensed;
  final int? imageWidth;

  const Settings(
      {required this.loadImages,
      required this.condensed,
      required this.imageWidth});

  Settings copyFrom(
      {bool? loadImages,
      bool? condensed,
      int? imageWidth,
      bool useImageWidthParameter = false}) {
    return Settings(
        loadImages: loadImages ?? this.loadImages,
        condensed: condensed ?? this.condensed,
        imageWidth: useImageWidthParameter
            ? imageWidth
            : (imageWidth ?? this.imageWidth));
  }

  @override
  List<Object?> get props => [loadImages, condensed, imageWidth];
}
