import 'package:equatable/equatable.dart';

class Settings extends Equatable {
  final bool loadImages;

  const Settings({required this.loadImages});

  @override
  List<Object?> get props => [loadImages];
}
