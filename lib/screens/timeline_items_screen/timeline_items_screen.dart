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
  final Timeline timeline;
  final TimelineHost timelineHost;
  final Settings settings;
  const TimelineItemsWidget(
      {super.key,
      required this.timeline,
      required this.timelineHost,
      required this.settings});

  @override
  State<TimelineItemsWidget> createState() => _TimelineItemsWidgetState();
}

class _TimelineItemsWidgetState extends State<TimelineItemsWidget> {
  final scrollController = ScrollController();
  late final ObserverControllerWithLazyLoading
      observerControllerWithLazyLoading;
  List<int> builtIndexes = [];
  //late final ListObserverController listObserverController;
  List<int> imageIndexes = [];
  List<int> imagesLoadedIndexes = [];

  @override
  void initState() {
    super.initState();
    // listObserverController =
    //     ListObserverController(controller: scrollController)
    //       ..cacheJumpIndexOffset = false;
    observerControllerWithLazyLoading = ObserverControllerWithLazyLoading(
        onBuiltEnd: onBuiltEnd, scrollController: scrollController)
      ..init();
  }

  void onBuiltEnd(List<int> indexes) async {
    print('Set builtIndexes to ${indexes.join(', ')}');
    setState(() {
      builtIndexes = indexes;
      imagesLoadedIndexes = List<int>.from(indexes);
    });
  }

  @override
  void dispose() {
    super.dispose();
    scrollController.dispose();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final repo = RepositoryProvider.of<TimelineRepository>(context);
    return BlocProvider(
      create: (context) => TimelineItemsScreenCubit(repo)
        ..getItems(widget.timelineHost, widget.timeline),
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
                            (timeStamp) {
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
                  child: RefreshIndicator(
                onRefresh: () {
                  return cubit.getItems(widget.timelineHost, widget.timeline,
                      refresh: true);
                },
                child: ListViewObserver(
                  controller:
                      observerControllerWithLazyLoading.listObserverController,
                  onObserve: observerControllerWithLazyLoading.onObserve,
                  child: ListView.builder(
                      controller: scrollController,
                      itemCount: state.items.timelineItems.length,
                      itemBuilder: (context, index) {
                        final e = state.items.timelineItems[index];
                        if (e is TimelineYearItem) {
                          return Card(
                            color: Colors.amberAccent,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                e.year.toString(),
                                style: const TextStyle(
                                    fontSize: 26, fontWeight: FontWeight.w900),
                              ),
                            ),
                          );
                        } else {
                          final TimelineItem item = e as TimelineItem;
                          final loadImage = observerControllerWithLazyLoading
                                  .shouldActivelyLoad(index, builtIndexes) &&
                              (widget.settings.loadImages ||
                                  imageIndexes.contains(index));
                          if (loadImage) {
                            print('Load image for $index');
                          }
                          return Card(
                            key:
                                observerControllerWithLazyLoading.getKey(index),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          item.title,
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.normal),
                                        ),
                                      ),
                                      if (!widget.settings.loadImages &&
                                          item.image != null)
                                        TextButton(
                                            onPressed: () {
                                              var tmp =
                                                  List<int>.from(imageIndexes);
                                              if (tmp.contains(index)) {
                                                tmp.remove(index);
                                              } else {
                                                tmp.add(index);
                                              }
                                              setState(() {
                                                imageIndexes = tmp;
                                              });
                                            },
                                            child: Text('Image'))
                                    ],
                                  ),
                                ),
                                if (item.intro.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: MyHtmlText.getRichText(item.intro),
                                  ),

                                // Load image only if we scroll manually (requestedIndex == -1) or when the index is less than 3 away from requestedIndex
                                if (loadImage)
                                  Image.network(
                                    item.image!,
                                  )
                              ],
                            ),
                          );
                        }
                      }),
                ),
              ))
            ],
          );
        },
      ),
    );
  }
}
