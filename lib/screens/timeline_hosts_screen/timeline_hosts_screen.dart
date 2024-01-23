import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeline/models/timeline_host.dart';
import 'package:timeline/my_input_dialog.dart';
import 'package:timeline/my_loading_overlay.dart';
import 'package:timeline/repositories/timeline_repository.dart';
import 'package:timeline/screens/timeline_host_screen.dart/timeline_host_screen.dart';
import 'package:timeline/screens/timeline_hosts_screen/timeline_hosts_screen_bloc.dart';

class TimelineHostsScreen extends StatefulWidget {
  final TimelineAll timelineAll;
  const TimelineHostsScreen({super.key, required this.timelineAll});

  @override
  State<TimelineHostsScreen> createState() => _TimelineHostsScreenState();
}

class _TimelineHostsScreenState extends State<TimelineHostsScreen> {
  final createHostController = TextEditingController();
  var selectionMode = false;
  Map<int, bool> selectedHosts = {};
  late int timelineAllHash;
  final _loadingOverlay = LoadingOverlay();
  @override
  void dispose() {
    createHostController.dispose();
    _loadingOverlay.hide();
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

  bool _isSelected(int hostId) {
    return selectedHosts.containsKey(hostId) && selectedHosts[hostId]!;
  }

  List<Widget> getHostTimelines(TimelineAll timelineAll, TimelineHost host,
      TimelineHostsScreenCubit cubit) {
    final isSelected = _isSelected(host.id);
    final List<Widget> widgets = [
      ListTile(
          // onLongPress: () {
          //   setState(() {
          //     selectionMode = !selectionMode;
          //     selectedHosts = {host.id: true};
          //   });
          // },
          onTap: () async {
            if (selectionMode) {
              var copy = Map<int, bool>.of(selectedHosts);
              if (isSelected) {
                copy.remove(host.id);
              } else {
                copy[host.id] = true;
              }
              setState(() {
                selectedHosts = copy;
              });
            } else {
              final oldHash = timelineAll.hashCode;
              final newHash = await Navigator.of(context).push<int?>(
                  MaterialPageRoute(
                      builder: (context) => TimelineHostScreen(
                          host: host, timelineAll: timelineAll)));
              if (mounted && (newHash == null || oldHash != newHash)) {
                _loadingOverlay.show(context);
                cubit.refresh();
              }
            }
          },
          // leading: Icon(selectionMode
          //     ? (isSelected ? Icons.check_box : Icons.check_box_outline_blank)
          //     : Icons.circle_outlined),
          trailing: const Icon(Icons.arrow_forward_ios),
          title:
              Text(host.host, style: Theme.of(context).textTheme.headlineSmall))
    ];
    for (final t in timelineAll.timelines) {
      if (t.hostId == host.id) {
        widgets.add(ListTile(title: Text(t.name)));
      }
    }
    return widgets;
  }

  void onAddHost(
      TimelineHostsScreenCubit cubit, TimelineAll timelineAll) async {
    createHostController.clear();
    final host = await MyInputDialog.show(
        context, createHostController, 'Enter new host');
    if (host != null) {
      cubit.addHost(host, timelineAll);
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
            setState(() {
              selectionMode = false;
              selectedHosts = {};
            });
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
            items.addAll(getHostTimelines(timelineAll, h, cubit));
          }
          return Scaffold(
              appBar: AppBar(
                title: const Text('Hosts'),
                actions: selectionMode
                    ? [
                        IconButton(
                            //color: Colors.red,
                            onPressed: selectedHosts.isNotEmpty
                                ? () {
                                    _loadingOverlay.show(context);
                                    cubit.removeHosts(
                                        selectedHosts.keys.toList());
                                  }
                                : null,
                            icon: const Icon(Icons.delete))
                      ]
                    : [
                        IconButton(
                            onPressed: () async {
                              onAddHost(cubit, timelineAll);
                            },
                            icon: const Icon(Icons.add))
                      ],
              ),
              body: items.isNotEmpty
                  ? Column(children: items)
                  : Center(
                      child: ElevatedButton(
                        onPressed: () {
                          onAddHost(cubit, timelineAll);
                        },
                        child: const Text('Add host'),
                      ),
                    ));
        },
      ),
    );
  }
}
