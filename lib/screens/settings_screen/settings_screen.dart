import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeline/models/settings.dart';
import 'package:timeline/screens/settings_screen/settings_screen_bloc.dart';

class SettingsScreen extends StatefulWidget {
  final Settings initialSettings;
  const SettingsScreen({super.key, required this.initialSettings});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController imageWidthController;

  @override
  void initState() {
    super.initState();
    imageWidthController = TextEditingController(
        text: widget.initialSettings.imageWidth?.toString());
  }

  @override
  void dispose() {
    imageWidthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingsScreenCubit(widget.initialSettings),
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
                            imageWidth: state.settings.imageWidth,
                            condensed: newValue));
                      }
                    }),
                if (!state.settings.condensed) ...[
                  CheckboxListTile(
                      title: Text('Load images'),
                      value: state.settings.loadImages,
                      onChanged: (newValue) {
                        if (newValue != null) {
                          cubit.updateSettings(Settings(
                              imageWidth: state.settings.imageWidth,
                              loadImages: newValue,
                              condensed: state.settings.condensed));
                        }
                      }),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(child: Text('Image width')),
                        Expanded(
                            child: TextField(
                          controller: imageWidthController,
                          onChanged: (value) {
                            final valueInt =
                                value.isNotEmpty ? int.tryParse(value) : null;

                            cubit.updateSettings(Settings(
                                imageWidth: valueInt,
                                loadImages: state.settings.loadImages,
                                condensed: state.settings.condensed));
                          },
                        ))
                      ],
                    ),
                  )
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
