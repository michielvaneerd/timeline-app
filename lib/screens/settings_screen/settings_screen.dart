import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeline/models/settings.dart';
import 'package:timeline/screens/settings_screen/settings_screen_bloc.dart';

class SettingsScreen extends StatelessWidget {
  final Settings initialSettings;
  const SettingsScreen({super.key, required this.initialSettings});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingsScreenCubit(initialSettings),
      child: BlocBuilder<SettingsScreenCubit, SettingsScreenState>(
        builder: (context, state) {
          final cubit = BlocProvider.of<SettingsScreenCubit>(context);
          return Scaffold(
            appBar: AppBar(title: Text('Settings')),
            body: Column(
              children: [
                CheckboxListTile(
                    title: Text('Condensed view'),
                    value: state.settings.condensed,
                    onChanged: (newValue) {
                      if (newValue != null) {
                        cubit.updateSettings(Settings(
                            loadImages: state.settings.loadImages,
                            condensed: newValue));
                      }
                    }),
                if (!state.settings.condensed)
                  CheckboxListTile(
                      title: Text('Load images'),
                      value: state.settings.loadImages,
                      onChanged: (newValue) {
                        if (newValue != null) {
                          cubit.updateSettings(Settings(
                              loadImages: newValue,
                              condensed: state.settings.condensed));
                        }
                      }),
              ],
            ),
          );
        },
      ),
    );
  }
}
