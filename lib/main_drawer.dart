import 'package:flutter/material.dart';
import 'package:timeline/main_cubit.dart';
import 'package:timeline/repositories/timeline_repository.dart';
import 'package:timeline/screens/settings_screen/settings_screen.dart';
import 'package:timeline/screens/timeline_hosts_screen/timeline_hosts_screen.dart';

class MainDrawer extends StatefulWidget {
  const MainDrawer(
      {super.key, required this.timelineAll, required this.mainCubit});
  final TimelineAll timelineAll;
  final MainCubit mainCubit;

  @override
  State<MainDrawer> createState() => _MainDrawerState();
}

class _MainDrawerState extends State<MainDrawer> {
  late List<int> activeTimelineIds;

  @override
  void initState() {
    super.initState();
    activeTimelineIds = widget.timelineAll.timelines
        .where((element) => element.isActive())
        .map((e) => e.id)
        .toList();
  }

  List<Widget> _getDrawerItems(BuildContext context) {
    final List<Widget> items = [];
    for (final host in widget.timelineAll.timelineHosts) {
      items.add(ListTile(
        title: Text(host.host),
        titleTextStyle: TextStyle(fontSize: 20, color: Colors.black),
      ));
      for (final timeline in widget.timelineAll.timelines
          .where((element) => element.hostId == host.id)) {
        items.add(CheckboxListTile(
          title: Text(timeline.name),
          value: activeTimelineIds.contains(timeline.id),
          onChanged: (newValue) {
            if (newValue != null) {
              var tmp = List<int>.from(activeTimelineIds);
              if (newValue) {
                if (!tmp.contains(timeline.id)) {
                  tmp.add(timeline.id);
                }
              } else {
                tmp.remove(timeline.id);
              }
              setState(() {
                activeTimelineIds = tmp;
              });
            }
          },
        ));
      }
    }
    items.add(ListTile(
      title: Text('OK'),
      onTap: () {
        Navigator.of(context).pop();
        widget.mainCubit.activateTimelines(activeTimelineIds);
      },
    ));
    items.add(ListTile(
      title: Text('Hosts'),
      onTap: () async {
        Navigator.of(context).pop();
        await Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => TimelineHostsScreen(
                  timelineAll: widget.timelineAll,
                )));
        widget.mainCubit.checkAtStart(withBusy: false);
      },
    ));
    items.add(ListTile(
      title: Text('Settings'),
      titleTextStyle: TextStyle(color: Colors.black, fontSize: 20),
      onTap: () async {
        Navigator.of(context).pop(); // Drawer
        await Navigator.of(context).push(MaterialPageRoute(
            builder: (context) =>
                SettingsScreen(initialSettings: widget.timelineAll.settings)));
        widget.mainCubit.checkAtStart();
      },
    ));
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: _getDrawerItems(context),
      ),
    );
  }
}
