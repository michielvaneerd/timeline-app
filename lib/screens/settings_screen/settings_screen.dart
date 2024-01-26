import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeline/models/settings.dart';
import 'package:timeline/my_loading_overlay.dart';
import 'package:timeline/screens/settings_screen/settings_screen_bloc.dart';
import 'package:timeline/utils.dart';

class SettingsScreen extends StatefulWidget {
  final Settings initialSettings;
  const SettingsScreen({super.key, required this.initialSettings});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController imageWidthController;
  late Settings settings;
  final _loadingOverlay = LoadingOverlay();

  @override
  void initState() {
    super.initState();
    settings = widget.initialSettings.copyFrom();
    imageWidthController = TextEditingController(
        text: widget.initialSettings.imageWidth?.toString());
  }

  @override
  void dispose() {
    imageWidthController.dispose();
    _loadingOverlay.hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingsScreenCubit(widget.initialSettings),
      child: BlocBuilder<SettingsScreenCubit, SettingsScreenState>(
        builder: (context, state) {
          final cubit = BlocProvider.of<SettingsScreenCubit>(context);
          return PopScope(
            canPop: false,
            onPopInvoked: (didPop) async {
              if (didPop) {
                return;
              }
              _loadingOverlay.show(context);
              await cubit.updateSettings(settings);
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
            child: Scaffold(
              appBar: AppBar(title: Text(myLoc(context).settings)),
              body: Column(
                children: [
                  CheckboxListTile(
                      title: Text(myLoc(context).condensedView),
                      value: settings.condensed,
                      onChanged: (newValue) {
                        if (newValue != null) {
                          setState(() {
                            settings = settings.copyFrom(condensed: newValue);
                          });
                        }
                      }),
                  if (!settings.condensed) ...[
                    CheckboxListTile(
                        title: Text(myLoc(context).loadImagesByDefault),
                        value: settings.loadImages,
                        onChanged: (newValue) {
                          if (newValue != null) {
                            setState(() {
                              settings =
                                  settings.copyFrom(loadImages: newValue);
                            });
                          }
                        }),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(child: Text(myLoc(context).imageWidth)),
                          Expanded(
                              child: TextField(
                            controller: imageWidthController,
                            onChanged: (value) {
                              final valueInt =
                                  value.isNotEmpty ? int.tryParse(value) : null;
                              setState(() {
                                settings = settings.copyFrom(
                                    imageWidth: valueInt,
                                    useImageWidthParameter: true);
                              });
                            },
                          ))
                        ],
                      ),
                    )
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
