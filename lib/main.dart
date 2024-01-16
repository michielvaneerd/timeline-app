import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeline/main_cubit.dart';
import 'package:timeline/main_drawer.dart';
import 'package:timeline/my_http.dart';
import 'package:timeline/my_store.dart';
import 'package:timeline/repositories/timeline_repository.dart';
import 'package:timeline/screens/settings_screen/settings_screen.dart';
import 'package:timeline/screens/timeline_hosts_screen/timeline_hosts_screen.dart';
import 'package:timeline/screens/timeline_items_screen/timeline_items_screen.dart';
import 'package:timeline/screens/timeline_items_screen/timeline_items_screen_test_4.dart';
import 'package:timeline/screens/timeline_items_screen/timeline_items_screen_test_5.dart';

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
        theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          primary: Colors.black,
        )),
        home: BlocProvider(
          create: (context) => MainCubit(repo)..checkAtStart(),
          child: const MyApp(),
        )),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MainCubit, MainState>(
      listener: (context, state) {
        // TODO: implement listener
      },
      builder: (context, state) {
        final cubit = BlocProvider.of<MainCubit>(context);
        final activeTimelines = state.timelineAll?.timelines.where(
          (element) => element.isActive(),
        );
        return Scaffold(
            appBar: AppBar(
              title: Text(activeTimelines != null && activeTimelines.isNotEmpty
                  ? activeTimelines.map((e) => e.name).join(', ')
                  : 'Timeline'),
              actions: activeTimelines != null && activeTimelines.isNotEmpty
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
                ? MainDrawer(
                    timelineAll: state.timelineAll!,
                    mainCubit: cubit,
                  )
                : null,
            body: Center(
              child: state.busy
                  ? const CircularProgressIndicator()
                  : (activeTimelines != null && activeTimelines.isNotEmpty
                      ?
                      //const MyTestItemsScreen5()
                      TimelineItemsWidget(
                          settings: state.timelineAll!.settings,
                          activeTimelines: activeTimelines.toList(),
                          timelineHosts: state.timelineAll!.timelineHosts)
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
                                    //cubit.activateTimeline(timelineId);
                                    // TODO...
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
