import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeline/main_cubit.dart';
import 'package:timeline/my_http.dart';
import 'package:timeline/my_store.dart';
import 'package:timeline/repositories/timeline_repository.dart';
import 'package:timeline/screens/timeline_hosts_screen/timeline_hosts_screen.dart';
import 'package:timeline/screens/timeline_items_screen/timeline_items_screen.dart';
import 'package:timeline/screens/timeline_items_screen/timeline_items_screen_test.dart';

// https://github.com/fluttercandies/flutter_scrollview_observer/blob/main/lib/src/common/observer_controller.dart#L334
// https://pub.dev/packages/scroll_to_index

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MyStore.init();
  final repo = TimelineRepository(myHttp: MyHttp());
  runApp(RepositoryProvider.value(
    value: repo,
    child: MaterialApp(
        title: 'Timeline',
        home: BlocProvider(
          create: (context) => MainCubit(repo)..checkAtStart(),
          child: const MyApp(),
        )),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  List<Widget> _getDrawerItems(
      TimelineAll timelineAll, MainCubit cubit, BuildContext context) {
    final List<Widget> items = [];
    for (final host in timelineAll.timelineHosts) {
      items.add(ListTile(
        title: Text(host.host),
      ));
      for (final timeline in timelineAll.timelines
          .where((element) => element.hostId == host.id)) {
        items.add(ListTile(
          title: Text(timeline.name),
          onTap: () {
            cubit.activateTimeline(timeline.id);
            Navigator.of(context).pop();
          },
        ));
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MainCubit, MainState>(
      listener: (context, state) {
        // TODO: implement listener
      },
      builder: (context, state) {
        final cubit = BlocProvider.of<MainCubit>(context);
        return Scaffold(
            appBar: AppBar(
              title: Text(state.timelineAll?.activeTimeline != null
                  ? state.timelineAll!.activeTimeline!.name
                  : 'Timeline'),
              actions: state.timelineAll?.activeTimeline != null
                  ? [
                      TextButton(
                          onPressed: () {
                            cubit.closeTimeline();
                          },
                          child: const Text('Close'))
                    ]
                  : null,
            ),
            drawer: state.timelineAll != null
                ? Drawer(
                    child: ListView(
                      children:
                          _getDrawerItems(state.timelineAll!, cubit, context),
                    ),
                  )
                : null,
            body: Center(
              child: state.busy
                  ? const CircularProgressIndicator()
                  : (state.timelineAll?.activeTimeline != null
                      ? const MyTestItemsScreen()
                      // TimelineItemsWidget(
                      //     timeline: state.timelineAll!.activeTimeline!,
                      //     timelineHost: state.timelineAll!.activeHost!)
                      : ElevatedButton(
                          onPressed: state.timelineAll != null
                              ? () async {
                                  final timelineId = await Navigator.of(context)
                                      .push(MaterialPageRoute(
                                          builder: (context) =>
                                              TimelineHostsScreen(
                                                timelineAll: state.timelineAll!,
                                              )));
                                  if (timelineId != null) {
                                    cubit.activateTimeline(timelineId);
                                  } else {
                                    // TODO: we can check if timelineAll has changed...
                                    cubit.checkAtStart(withBusy: false);
                                  }
                                }
                              : null,
                          child: const Text('Add Host'))),
            ));
      },
    );
  }
}
