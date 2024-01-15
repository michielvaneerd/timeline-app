import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeline/models/settings.dart';
import 'package:timeline/my_store.dart';

class SettingsScreenState extends Equatable {
  final Settings settings;

  const SettingsScreenState({required this.settings});
  @override
  List<Object?> get props => [settings];
}

class SettingsScreenCubit extends Cubit<SettingsScreenState> {
  SettingsScreenCubit(Settings settings)
      : super(SettingsScreenState(settings: settings));

  void updateSettings(Settings settings) async {
    await MyStore.putSettings(settings);
    emit(SettingsScreenState(settings: settings));
  }
}
