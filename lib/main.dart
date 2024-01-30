import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeline/main_cubit.dart';
import 'package:timeline/main_drawer.dart';
import 'package:timeline/my_crypt.dart';
import 'package:timeline/my_http.dart';
import 'package:timeline/my_store.dart';
import 'package:timeline/color_schemes5.g.dart';
import 'package:timeline/repositories/timeline_repository.dart';
import 'package:timeline/screens/timeline_hosts_screen/timeline_hosts_screen.dart';
import 'package:timeline/screens/timeline_items_screen/timeline_items_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:timeline/utils.dart';

// https://github.com/fluttercandies/flutter_scrollview_observer/blob/main/lib/src/common/observer_controller.dart#L334
// https://pub.dev/packages/scroll_to_index

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MyStore.init();
  final repo = TimelineRepository(myHttp: MyHttp());
  runApp(RepositoryProvider.value(
    value: repo,
    child: BlocProvider(
      create: (context) => MainCubit(repo)..checkAtStart(),
      child: BlocBuilder<MainCubit, MainState>(
        builder: (context, state) {
          return MaterialApp(
              title: 'Timeline',
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              theme: lightColorTheme,
              darkTheme: darkColorTheme,
              themeMode: state.timelineAll?.settings.getThemeMode(),
              home: const MyApp());
        },
      ),
    ),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var showSearch = false;

  Widget infoWidget(MainState state, MainCubit cubit) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.timelineAll!.timelines.isNotEmpty)
          Card(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    myLoc(context).selectTimelinesInfoText,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Builder(builder: (context) {
                    return FilledButton(
                        onPressed: () async {
                          Scaffold.of(context).openDrawer();
                        },
                        child: Text(myLoc(context).ok));
                  }),
                )
              ],
            ),
          ),
        const Padding(
          padding: EdgeInsets.only(top: 16),
        ),
        Card(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  myLoc(context).addHostInfoText,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: FilledButton(
                    onPressed: () async {
                      await Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => TimelineHostsScreen(
                                showAddHostDialog: true,
                                timelineAll: state.timelineAll!,
                              )));
                      cubit.checkAtStart();
                    },
                    child: Text(myLoc(context).addHost)),
              ),
            ],
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MainCubit, MainState>(
      listener: (context, state) {
        if (state.busy) {
          setState(() {
            showSearch = false;
          });
        }
      },
      builder: (context, state) {
        final cubit = BlocProvider.of<MainCubit>(context);
        final activeTimelines = state.timelineAll?.timelines.where(
          (element) => element.isActive(),
        );
        return Scaffold(
            appBar: AppBar(
              //backgroundColor: Theme.of(context).secondaryHeaderColor,
              title: Text(activeTimelines != null && activeTimelines.isNotEmpty
                  ? activeTimelines.map((e) => e.name).join(', ')
                  : myLoc(context).timeline),
              actions: activeTimelines != null && activeTimelines.isNotEmpty
                  ? [
                      IconButton(
                          onPressed: () {
                            setState(() {
                              showSearch = !showSearch;
                            });
                          },
                          icon: const Icon(Icons.search))
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
                      ? TimelineItemsWidget(
                          showSearch: showSearch,
                          timelineAll: state.timelineAll!,
                          yearAndTimelineItems: state.items!,
                          onRefresh: () {
                            cubit.checkAtStart(withBusy: true, refresh: true);
                          },
                        )
                      : infoWidget(state, cubit)),
            ));
      },
    );
  }
}
