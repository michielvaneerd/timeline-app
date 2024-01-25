import 'package:equatable/equatable.dart';

class Settings extends Equatable {
  final bool loadImages;
  final bool condensed;
  final int? imageWidth;

  const Settings(
      {required this.loadImages,
      required this.condensed,
      required this.imageWidth});

  @override
  List<Object?> get props => [loadImages, condensed, imageWidth];
}
