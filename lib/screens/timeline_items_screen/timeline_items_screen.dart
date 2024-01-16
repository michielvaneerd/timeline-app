import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scrollview_observer/scrollview_observer.dart';
import 'package:timeline/models/settings.dart';
import 'package:timeline/models/timeline.dart';
import 'package:timeline/models/timeline_host.dart';
import 'package:timeline/models/timeline_item.dart';
import 'package:timeline/my_html_text.dart';
import 'package:timeline/repositories/timeline_repository.dart';
import 'package:timeline/screens/timeline_items_screen/observer_controller_with_lazy_loading.dart';
import 'package:timeline/screens/timeline_items_screen/timeline_items_screen_bloc.dart';

// https://github.com/fluttercandies/flutter_scrollview_observer/blob/main/lib/src/common/observer_controller.dart#L334
// https://pub.dev/packages/scroll_to_index

class TimelineItemsWidget extends StatefulWidget {
  final List<Timeline> activeTimelines;
  final List<TimelineHost> timelineHosts;
  final Settings settings;
  final bool showSearch;
  const TimelineItemsWidget(
      {super.key,
      required this.activeTimelines,
      required this.showSearch,
      required this.timelineHosts,
      required this.settings});

  @override
  State<TimelineItemsWidget> createState() => _TimelineItemsWidgetState();
}

class _TimelineItemsWidgetState extends State<TimelineItemsWidget> {
  final scrollController = ScrollController();
  late final ObserverControllerWithLazyLoading
      observerControllerWithLazyLoading;
  List<int> builtIndexes = [];
  List<int> imageIndexes = [];

  @override
  void initState() {
    super.initState();
    observerControllerWithLazyLoading = ObserverControllerWithLazyLoading(
        onBuiltEnd: onBuiltEnd, scrollController: scrollController)
      ..init();
  }

  void onBuiltEnd(List<int> indexes) async {
    setState(() {
      builtIndexes = indexes;
    });
  }

  @override
  void dispose() {
    super.dispose();
    scrollController.dispose();
  }

  Widget getRefreshIndicatorOrContainer(
      Widget child, TimelineItemsScreenCubit cubit) {
    if (widget.activeTimelines.length > 1) {
      return Container(
        child: child,
      );
    } else {
      return RefreshIndicator(
          onRefresh: () {
            return cubit.getItems(widget.timelineHosts, widget.activeTimelines,
                refresh: true);
          },
          child: child);
    }
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final repo = RepositoryProvider.of<TimelineRepository>(context);
    return BlocProvider(
      create: (context) => TimelineItemsScreenCubit(repo)
        ..getItems(widget.timelineHosts, widget.activeTimelines),
      child: BlocBuilder<TimelineItemsScreenCubit, TimelineItemsScreenState>(
        builder: (context, state) {
          if (state.items.timelineItems.isEmpty) {
            return Container();
          }

          final cubit = BlocProvider.of<TimelineItemsScreenCubit>(context);
          return Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              SizedBox(
                  //color: Colors.green,
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: state.items.timelineItems
                        .whereType<TimelineYearItem>()
                        .map((e) {
                      return InkWell(
                        onTap: () async {
                          final index = state.items.yearIndexes[e.year]!;
                          await observerControllerWithLazyLoading
                              .scrollToIndex(index);
                          WidgetsBinding.instance.addPostFrameCallback(
                            (timeStamp) async {
                              await Future.delayed(const Duration(
                                  milliseconds:
                                      300)); // needed because images may still be loading so the list view items may get different height
                              observerControllerWithLazyLoading
                                  .scrollToIndex(index);
                            },
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Center(child: Text(e.year.toString())),
                        ),
                      );
                    }).toList(),
                  )),
              Expanded(
                  child: getRefreshIndicatorOrContainer(
                      ListViewObserver(
                        controller: observerControllerWithLazyLoading
                            .listObserverController,
                        onObserve: observerControllerWithLazyLoading.onObserve,
                        child: ListView.builder(
                            controller: scrollController,
                            itemCount: state.items.timelineItems.length,
                            itemBuilder: (context, index) {
                              final e = state.items.timelineItems[index];
                              if (e is TimelineYearItem) {
                                return Card(
                                  color: Colors.greenAccent,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      e.year.toString(),
                                      style: const TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w900),
                                    ),
                                  ),
                                );
                              } else {
                                final TimelineItem item = e as TimelineItem;
                                final loadImage =
                                    observerControllerWithLazyLoading
                                            .shouldActivelyLoad(
                                                index, builtIndexes) &&
                                        (widget.settings.loadImages ||
                                            imageIndexes.contains(index));
                                if (loadImage) {
                                  print('Load image for $index');
                                }
                                return Card(
                                  key: observerControllerWithLazyLoading
                                      .getKey(index),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Flexible(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item.title,
                                                    style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.normal),
                                                  ),
                                                  Text(item.year.toString(),
                                                      style: const TextStyle(
                                                          fontSize: 12))
                                                ],
                                              ),
                                            ),
                                            if (!widget.settings.loadImages &&
                                                item.image != null)
                                              IconButton(
                                                icon: const Icon(
                                                    Icons.image_outlined,
                                                    size: 16),
                                                onPressed: () {
                                                  var tmp = List<int>.from(
                                                      imageIndexes);
                                                  if (tmp.contains(index)) {
                                                    tmp.remove(index);
                                                  } else {
                                                    tmp.add(index);
                                                  }
                                                  setState(() {
                                                    imageIndexes = tmp;
                                                  });
                                                },
                                              )
                                          ],
                                        ),
                                      ),
                                      if (item.intro.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: MyHtmlText.getRichText(
                                              item.intro),
                                        ),

                                      // Load image only if we scroll manually (requestedIndex == -1) or when the index is less than 3 away from requestedIndex
                                      if (loadImage)
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Image.network(
                                            item.image!,
                                          ),
                                        ),
                                      if (item.links.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: item.links
                                                .map((e) => InkWell(
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(
                                                                bottom: 4.0),
                                                        child: Text(e,
                                                            style: const TextStyle(
                                                                fontSize: 12,
                                                                decoration:
                                                                    TextDecoration
                                                                        .underline)),
                                                      ),
                                                      onTap: () {
                                                        print('Go to $e');
                                                      },
                                                    ))
                                                .toList(),
                                          ),
                                        )
                                    ],
                                  ),
                                );
                              }
                            }),
                      ),
                      cubit))
            ],
          );
        },
      ),
    );
  }
}
