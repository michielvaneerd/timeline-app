import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeline/models/timeline_host.dart';
import 'package:timeline/my_host_input_dialog.dart';
import 'package:timeline/my_loading_overlay.dart';
import 'package:timeline/repositories/timeline_repository.dart';
import 'package:timeline/screens/timeline_hosts_screen/timeline_hosts_screen_bloc.dart';
import 'package:timeline/utils.dart';

class TimelineHostsScreen extends StatefulWidget {
  final TimelineAll timelineAll;
  const TimelineHostsScreen({super.key, required this.timelineAll});

  @override
  State<TimelineHostsScreen> createState() => _TimelineHostsScreenState();
}

class _TimelineHostsScreenState extends State<TimelineHostsScreen> {
  final hostInputDialog = MyHostInputDialog();
  late int timelineAllHash;
  final _loadingOverlay = LoadingOverlay();
  @override
  void dispose() {
    _loadingOverlay.hide();
    hostInputDialog.dispose();
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

  Widget getHostTimelines(TimelineAll timelineAll, TimelineHost host,
      TimelineHostsScreenCubit cubit) {
    final timelines = timelineAll.timelines
        .where((element) => element.hostId == host.id)
        .map((e) => ListTile(title: Text(e.name)))
        .toList();
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
              title: Text(host.name,
                  style: Theme.of(context).textTheme.headlineSmall)),
          ListTile(
              title: Text(host.host,
                  style: const TextStyle(fontWeight: FontWeight.bold))),
          ...timelines,
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FilledButton(
                      onPressed: () {
                        _loadingOverlay.show(context);
                        cubit.refreshHost(timelineAll, host);
                      },
                      child: Text(myLoc(context).refresh)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FilledButton(
                      style: ButtonStyle(
                          backgroundColor: MaterialStatePropertyAll(
                              Theme.of(context).colorScheme.error)),
                      onPressed: () async {
                        final response = await showDialog<bool?>(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              content: Text(
                                  myLoc(context).confirmDeleteHost(host.name)),
                              actions: [
                                TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop(false);
                                    },
                                    child: Text(myLoc(context).cancel)),
                                FilledButton(
                                    onPressed: () {
                                      Navigator.of(context).pop(true);
                                    },
                                    child: Text(myLoc(context).delete))
                              ],
                            );
                          },
                        );
                        if (mounted && response != null && response) {
                          _loadingOverlay.show(context);
                          cubit.removeHosts(timelineAll, [host.id]);
                        }
                      },
                      child: Text(myLoc(context).delete)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  void onAddHost(
      TimelineHostsScreenCubit cubit, TimelineAll timelineAll) async {
    hostInputDialog.clear();
    final response = await hostInputDialog.show(context);
    if (response != null) {
      cubit.addHost(response.host, response.name, timelineAll);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryProvider.of<TimelineRepository>(context);
    return BlocProvider(
      create: (context) => TimelineHostsScreenCubit(repo),
      child: BlocConsumer<TimelineHostsScreenCubit, TimelineHostsScreenState>(
        listener: (context, state) {
          if (!state.busy) {
            _loadingOverlay.hide();
          }
          if (state.error != null) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.error!)));
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
                      icon: const Icon(Icons.add))
                ],
              ),
              body: items.isNotEmpty
                  ? ListView(children: items)
                  : Center(
                      child: ElevatedButton(
                        onPressed: () {
                          onAddHost(cubit, timelineAll);
                        },
                        child: Text(myLoc(context).addHost),
                      ),
                    ));
        },
      ),
    );
  }
}
