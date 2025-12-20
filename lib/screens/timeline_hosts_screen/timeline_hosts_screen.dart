import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeline/models/timeline.dart';
import 'package:timeline/models/timeline_host.dart';
import 'package:timeline/my_color_picker_new.dart';
import 'package:timeline/my_text_fields_dialog.dart';
import 'package:timeline/my_loading_overlay.dart';
import 'package:timeline/my_widgets.dart';
import 'package:timeline/repositories/timeline_repository.dart';
import 'package:timeline/screens/draft_items_screen/draft_items_screen.dart';
import 'package:timeline/screens/timeline_hosts_screen/timeline_hosts_screen_bloc.dart';
import 'package:timeline/translation_helper.dart';
import 'package:timeline/utils.dart';

class TimelineHostsScreen extends StatefulWidget {
  final TimelineAll timelineAll;
  final bool showAddHostDialog;
  const TimelineHostsScreen({
    super.key,
    required this.timelineAll,
    this.showAddHostDialog = false,
  });

  @override
  State<TimelineHostsScreen> createState() => _TimelineHostsScreenState();
}

class _TimelineHostsScreenState extends State<TimelineHostsScreen> {
  bool hasShowedHostDialogOnStart = false;
  late final MyTextFieldsDialog myTwoFieldsDialog = MyTextFieldsDialog();
  late int timelineAllHash;
  final _loadingOverlay = LoadingOverlay();
  @override
  void dispose() {
    _loadingOverlay.hide();
    myTwoFieldsDialog.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    timelineAllHash = widget.timelineAll.hashCode;
  }

  TimelineAll _getTimelineAll(TimelineHostsScreenState? state) {
    return state?.timelineAll ?? widget.timelineAll;
  }

  Future onDelete(
    TimelineHost host,
    TimelineHostsScreenCubit cubit,
    TimelineAll timelineAll,
  ) async {
    final response = await showDialog<bool?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text(myLoc(context).confirmDeleteHost(host.name)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text(myLoc(context).cancel),
            ),
            FilledButton(
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(
                  Theme.of(context).colorScheme.error,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text(myLoc(context).delete),
            ),
          ],
        );
      },
    );
    if (mounted && response != null && response) {
      _loadingOverlay.show(context);
      cubit.removeHosts([host.id]);
    }
  }

  Future onLoginLogout(
    TimelineHost host,
    TimelineHostsScreenCubit cubit,
    TimelineAll timelineAll,
  ) async {
    if (host.username == null || host.username!.isEmpty) {
      myTwoFieldsDialog.clear();
      final result = await myTwoFieldsDialog.show(
        context,
        field1Text: myLoc(context).username,
        field2Text: myLoc(context).password,
        title: myLoc(context).login,
      );
      if (result != null &&
          result.field1.isNotEmpty &&
          result.field2!.isNotEmpty) {
        if (mounted) {
          _loadingOverlay.show(context);
          cubit.login(timelineAll, host, result.field1, result.field2!);
        }
      }
    } else {
      cubit.logout(timelineAll, host);
    }
  }

  Future onDraft(TimelineHost host, List<Timeline> timelines) async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            DraftItemsScreen(timelineHost: host, timelines: timelines),
      ),
    );
  }

  Future onRefresh(
    TimelineHost host,
    TimelineHostsScreenCubit cubit,
    TimelineAll timelineAll,
  ) async {
    _loadingOverlay.show(context);
    cubit.refreshHost(timelineAll, host);
  }

  Widget getHostTimelines(
    TimelineAll timelineAll,
    TimelineHost host,
    TimelineHostsScreenCubit cubit,
  ) {
    final timelines = timelineAll.timelines
        .where((element) => element.hostId == host.id)
        .toList();
    final timelineTiles = timelines.map((e) {
      final currentColorIntValue = e.color != null
          ? int.tryParse('0xFF${e.color}')
          : null;
      final currentColor = currentColorIntValue != null
          ? Color(currentColorIntValue)
          : Theme.of(context).colorScheme.tertiaryContainer;
      return ListTile(
        onTap: () async {
          final dialog = CommonColorPickerDialog(
            selectedColor: currentColorIntValue != null
                ? Color(currentColorIntValue)
                : null,
          );
          final newColor = await dialog.show(context: context);
          final newHex = newColor != null ? Utils.getHex(newColor) : null;
          cubit.updateTimelineColor(timeline: e, color: newHex);
        },
        leading: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: currentColor,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        title: Text(e.name),
        //subtitle: e.yearMin != null ? Text(e.yearMinMax()) : null,
        //subtitle: Text(e.color ?? ''),
      );
    }).toList();
    return Card(
      //elevation: 2.0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: ListTile(
                  title: Text(
                    host.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ),
              PopupMenuButton(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  switch (value) {
                    case 'delete':
                      onDelete(host, cubit, timelineAll);
                      break;
                    case 'login':
                      onLoginLogout(host, cubit, timelineAll);
                      break;
                    case 'logout':
                      onLoginLogout(host, cubit, timelineAll);
                      break;
                    case 'draft':
                      onDraft(host, timelines);
                      break;
                    case 'refresh':
                      onRefresh(host, cubit, timelineAll);
                      break;
                  }
                },
                itemBuilder: (context) {
                  return [
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(myLoc(context).delete),
                    ),
                    if (host.isLoggedIn())
                      PopupMenuItem(
                        value: 'logout',
                        child: Text(myLoc(context).logout),
                      ),
                    if (!host.isLoggedIn())
                      PopupMenuItem(
                        value: 'login',
                        child: Text(myLoc(context).login),
                      ),
                    PopupMenuItem(
                      value: 'refresh',
                      child: Text(myLoc(context).refresh),
                    ),
                  ];
                },
              ),
            ],
          ),
          ListTile(
            title: Text(
              host.host,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ...timelineTiles,
          if (host.isLoggedIn())
            ListTile(
              title: Text(myLoc(context).draftItems),
              onTap: () {
                onDraft(host, timelines);
              },
              trailing: const Icon(Icons.arrow_forward_ios),
            ),
        ],
      ),
    );
  }

  void onAddHost(
    TimelineHostsScreenCubit cubit,
    TimelineAll timelineAll,
  ) async {
    myTwoFieldsDialog.clear();
    final response = await myTwoFieldsDialog.show(
      context,
      field1Text: myLoc(context).name,
      field2Text: myLoc(context).host,
      title: myLoc(context).addHost,
    );
    if (response != null &&
        response.field1.isNotEmpty &&
        response.field2!.isNotEmpty) {
      cubit.addHost(response.field1, response.field2!, timelineAll);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryProvider.of<TimelineRepository>(context);
    return BlocProvider(
      create: (context) =>
          TimelineHostsScreenCubit(repo)
            ..showAddHostOnStart(widget.showAddHostDialog),
      child: BlocConsumer<TimelineHostsScreenCubit, TimelineHostsScreenState>(
        listener: (context, state) {
          if (!state.busy) {
            _loadingOverlay.hide();
          }
          if (state.exception != null) {
            MyWidgets.showSnackBarError(
              context,
              TranslationHelper.getMyExceptionMessage(
                context,
                state.exception!,
              ),
            );
          }
          if (state.showAddHostOnStart) {
            onAddHost(
              BlocProvider.of<TimelineHostsScreenCubit>(context),
              _getTimelineAll(state),
            );
          }
        },
        builder: (context, state) {
          final cubit = BlocProvider.of<TimelineHostsScreenCubit>(context);
          final timelineAll = _getTimelineAll(state);
          final List<Widget> items = [];
          for (final h in timelineAll.timelineHosts) {
            items.add(getHostTimelines(timelineAll, h, cubit));
          }
          return Scaffold(
            appBar: AppBar(
              title: Text(myLoc(context).hosts),
              actions: [
                IconButton(
                  onPressed: () async {
                    onAddHost(cubit, timelineAll);
                  },
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            body: items.isNotEmpty ? ListView(children: items) : Container(),
          );
        },
      ),
    );
  }
}
