import 'package:equatable/equatable.dart';

class Settings extends Equatable {
  final bool loadImages;
  final bool condensed;

  const Settings({required this.loadImages, required this.condensed});

  @override
  List<Object?> get props => [loadImages, condensed];
}
