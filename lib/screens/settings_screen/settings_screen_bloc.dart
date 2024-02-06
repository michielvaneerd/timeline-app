import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeline/models/settings.dart';
import 'package:timeline/my_store.dart';

class SettingsScreenState extends Equatable {
  final Settings settings;
  final bool busy;

  const SettingsScreenState({required this.settings, this.busy = false});
  @override
  List<Object?> get props => [settings, busy];
}

class SettingsScreenCubit extends Cubit<SettingsScreenState> {
  SettingsScreenCubit(Settings settings)
      : super(SettingsScreenState(settings: settings));

  Future updateSettings(Settings settings) async {
    await MyStore.putSettings(settings);
  }

  void clearCache(Settings settings) async {
    emit(SettingsScreenState(settings: settings, busy: true));
    await MyStore.clearImageCache();
    await Future.delayed(const Duration(seconds: 1));
    emit(SettingsScreenState(settings: settings));
  }
}
