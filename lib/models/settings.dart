import 'package:equatable/equatable.dart';

class Settings extends Equatable {
  final bool loadImages;
  final int? activeTimelineId;

  const Settings({required this.loadImages, required this.activeTimelineId});

  @override
  List<Object?> get props => [loadImages, activeTimelineId];
}
