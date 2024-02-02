import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scrollview_observer/scrollview_observer.dart';
import 'package:timeline/models/timeline.dart';
import 'package:timeline/models/timeline_item.dart';
import 'package:timeline/my_html_text.dart';
import 'package:timeline/my_store.dart';
import 'package:timeline/my_widgets.dart';
import 'package:timeline/repositories/timeline_repository.dart';
import 'package:timeline/screens/timeline_items_screen/observer_controller_with_lazy_loading.dart';
import 'package:timeline/screens/timeline_items_screen/timeline_items_screen_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

// https://github.com/fluttercandies/flutter_scrollview_observer/blob/main/lib/src/common/observer_controller.dart#L334
// https://pub.dev/packages/scroll_to_index

class TimelineItemsWidget extends StatefulWidget {
  final TimelineAll timelineAll;
  final YearAndTimelineItems yearAndTimelineItems;
  final bool showSearch;
  final void Function() onRefresh;
  const TimelineItemsWidget(
      {super.key,
      required this.timelineAll,
      required this.yearAndTimelineItems,
      required this.onRefresh,
      required this.showSearch});

  @override
  State<TimelineItemsWidget> createState() => _TimelineItemsWidgetState();
}

class _TimelineItemsWidgetState extends State<TimelineItemsWidget> {
  //MyHtmlText? myHtmlText;
  final scrollController = ScrollController();
  final yearScrollController = ScrollController();
  late final ObserverControllerWithLazyLoading
      observerControllerWithLazyLoading;
  List<int> builtIndexes = [];
  List<int> imageIndexes = [];
  final searchController = TextEditingController();
  late final double screenWidth;
  late double imageWidth;
  late final double pixelRatio;

  @override
  void initState() {
    super.initState();
    pixelRatio =
        WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    screenWidth = WidgetsBinding
            .instance.platformDispatcher.views.first.physicalSize.width /
        pixelRatio;
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
    scrollController.dispose();
    yearScrollController.dispose();
    searchController.dispose();
    //myHtmlText?.dispose();
    super.dispose();
  }

  Widget getRefreshIndicatorOrContainer(Widget child,
      TimelineItemsScreenCubit cubit, List<Timeline> activeTimelines) {
    if (activeTimelines.length > 1) {
      return Container(
        child: child,
      );
    } else {
      return RefreshIndicator(
          onRefresh: () async {
            await Future.delayed(const Duration(seconds: 1));
            widget.onRefresh();
          },
          child: child);
    }
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // We need to dispose the gesture recognizers from the rich texts...
    // if (myHtmlText != null) {
    //   myHtmlText!.dispose();
    // }
    // myHtmlText = MyHtmlText();
    final activeTimelines = widget.timelineAll.timelines
        .where(
          (element) => element.isActive(),
        )
        .toList();
    final repo = RepositoryProvider.of<TimelineRepository>(context);
    return BlocProvider(
      create: (context) => TimelineItemsScreenCubit(repo),
      child: BlocBuilder<TimelineItemsScreenCubit, TimelineItemsScreenState>(
        builder: (context, state) {
          if (widget.yearAndTimelineItems.timelineItems.isEmpty) {
            return Container();
          }

          imageWidth = widget.timelineAll.settings.imageWidth != null
              ? (widget.timelineAll.settings.imageWidth!.toDouble())
              : screenWidth;
          final cubit = BlocProvider.of<TimelineItemsScreenCubit>(context);
          final realItems = state.filteredItems ?? widget.yearAndTimelineItems;
          final yearItems =
              realItems.timelineItems.whereType<TimelineYearItem>().toList();
          final suffixIcon = state.filter.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    cubit.filterItems('', widget.yearAndTimelineItems,
                        widget.timelineAll.settings);
                    searchController.clear();
                  },
                  icon: const Icon(Icons.close))
              : null;
          return Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              if (widget.showSearch)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: MyWidgets.textField(
                    context,
                    controller: searchController,
                    suffixIcon: suffixIcon,
                    onChanged: (value) {
                      cubit.filterItems(value, widget.yearAndTimelineItems,
                          widget.timelineAll.settings);
                    },
                  ),
                ),
              Container(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  height: 90,
                  child: Scrollbar(
                    interactive: true,
                    thickness: 8,
                    scrollbarOrientation: ScrollbarOrientation.top,
                    controller: yearScrollController,
                    child: ListView.builder(
                      controller: yearScrollController,
                      itemCount: yearItems.length,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        final item = yearItems[index];
                        return Container(
                          width: 100,
                          //height: 70,
                          padding: const EdgeInsets.all(12.0),
                          child: Material(
                            color: Theme.of(context).colorScheme.inversePrimary,
                            borderRadius: BorderRadius.circular(32),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(32),
                              onTap: () async {
                                final index = realItems.yearIndexes[item.year]!;
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: Center(
                                    child: Text(
                                  item.year.toString(),
                                  style: Theme.of(context).textTheme.bodyLarge,
                                )),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  )),
              Expanded(
                  child: getRefreshIndicatorOrContainer(
                      ListViewObserver(
                        controller: observerControllerWithLazyLoading
                            .listObserverController,
                        onObserve: observerControllerWithLazyLoading.onObserve,
                        child: Scrollbar(
                          thickness: 8,
                          interactive: true,
                          controller: scrollController,
                          child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              controller: scrollController,
                              itemCount: realItems.timelineItems.length,
                              itemBuilder: (context, index) {
                                final e = realItems.timelineItems[index];
                                if (e is TimelineYearItem) {
                                  return Card(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        e.year.toString(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineLarge,
                                      ),
                                    ),
                                  );
                                } else {
                                  final TimelineItem item = e as TimelineItem;
                                  // final richTexts =
                                  //     !widget.timelineAll.settings.condensed &&
                                  //             item.intro.isNotEmpty
                                  //         ? myHtmlText!.getRichText(item.intro,
                                  //             textStyle: Theme.of(context)
                                  //                 .textTheme
                                  //                 .bodyLarge)
                                  //         : null;
                                  final timeline = activeTimelines.firstWhere(
                                      (element) => element.id == e.timelineId);
                                  final loadImage = item.image != null &&
                                      observerControllerWithLazyLoading
                                          .shouldActivelyLoad(
                                              index, builtIndexes) &&
                                      (widget.timelineAll.settings.loadImages ||
                                          imageIndexes.contains(index));
                                  final yearText = item.year.toString() +
                                      (item.yearEnd != null
                                          ? (' / ${item.yearEnd}')
                                          : '');
                                  return Card(
                                    // color:
                                    //     Theme.of(context).colorScheme.surface,
                                    key: observerControllerWithLazyLoading
                                        .getKey(index),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Flexible(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    if (activeTimelines.length >
                                                        1) ...[
                                                      Container(
                                                        decoration: BoxDecoration(
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .tertiaryContainer,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        4)),
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 8.0,
                                                                vertical: 2.0),
                                                        child: Text(
                                                            timeline.name,
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .bodySmall!
                                                                .copyWith(
                                                                    color: Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .onTertiaryContainer)),
                                                      ),
                                                      const Padding(
                                                          padding:
                                                              EdgeInsets.only(
                                                                  top: 4.0))
                                                    ],
                                                    Text(
                                                      item.title,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleLarge,
                                                    ),
                                                    Text(yearText,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodySmall),
                                                  ],
                                                ),
                                              ),
                                              if (!widget.timelineAll.settings
                                                      .condensed &&
                                                  !widget.timelineAll.settings
                                                      .loadImages &&
                                                  item.image != null)
                                                InkWell(
                                                  child: Icon(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary,
                                                      Icons.image_outlined,
                                                      size: Theme.of(context)
                                                          .textTheme
                                                          .titleLarge
                                                          ?.fontSize),
                                                  onTap: () {
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
                                        if (!widget.timelineAll.settings
                                                .condensed &&
                                            item.intro.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: MyHtmlText.getRichText(
                                                item.intro,
                                                textStyle: Theme.of(context)
                                                    .textTheme
                                                    .bodyLarge),
                                          ),

                                        // Load image only if we scroll manually (requestedIndex == -1) or when the index is less than 3 away from requestedIndex
                                        if (!widget.timelineAll.settings
                                                .condensed &&
                                            loadImage) ...[
                                          const Padding(
                                            padding: EdgeInsets.only(top: 8.0),
                                          ),
                                          Center(
                                            //widthFactor: imageWidth,
                                            child: Column(
                                              // crossAxisAlignment:
                                              //     CrossAxisAlignment.stretch,
                                              children: [
                                                Image.network(
                                                  item.image!,
                                                  width: imageWidth,
                                                  errorBuilder: (context, error,
                                                          stackTrace) =>
                                                      Placeholder(
                                                    fallbackHeight: imageWidth,
                                                    fallbackWidth: imageWidth,
                                                  ),
                                                  cacheWidth:
                                                      (imageWidth * pixelRatio)
                                                          .toInt(),
                                                ),
                                                if ((item.imageInfo != null &&
                                                        item.imageInfo!
                                                            .isNotEmpty) ||
                                                    (item.imageSource != null &&
                                                        item.imageSource!
                                                            .isNotEmpty))
                                                  Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      if (item.imageInfo !=
                                                          null)
                                                        Flexible(
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(8.0),
                                                            child: Align(
                                                              alignment: Alignment
                                                                  .centerRight,
                                                              child: Text(
                                                                  item
                                                                      .imageInfo!,
                                                                  style: Theme.of(
                                                                          context)
                                                                      .textTheme
                                                                      .bodySmall!
                                                                      .copyWith(
                                                                          color: Theme.of(context)
                                                                              .colorScheme
                                                                              .secondary)),
                                                            ),
                                                          ),
                                                        ),
                                                      if (item.imageSource !=
                                                              null &&
                                                          item.imageSource!
                                                              .isNotEmpty)
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(8.0),
                                                          child: Align(
                                                            alignment: Alignment
                                                                .centerRight,
                                                            child: InkWell(
                                                              onTap: () {
                                                                ScaffoldMessenger.of(
                                                                        context)
                                                                    .showSnackBar(SnackBar(
                                                                        content:
                                                                            Text(item.imageSource!)));
                                                              },
                                                              child: Text(
                                                                  'Source',
                                                                  style: Theme.of(
                                                                          context)
                                                                      .textTheme
                                                                      .bodySmall),
                                                            ),
                                                          ),
                                                        )
                                                    ],
                                                  ),
                                              ],
                                            ),
                                          )
                                        ],
                                        if (!widget.timelineAll.settings
                                                .condensed &&
                                            item.links.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text('Links',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleSmall),
                                                ...item.links
                                                    .map((e) => InkWell(
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .only(
                                                                    bottom:
                                                                        4.0),
                                                            child: Text(e.name,
                                                                style: Theme.of(
                                                                        context)
                                                                    .textTheme
                                                                    .bodySmall
                                                                    ?.copyWith(
                                                                        decoration:
                                                                            TextDecoration.underline)),
                                                          ),
                                                          onTap: () async {
                                                            if (!await launchUrl(
                                                                Uri.parse(
                                                                    e.url))) {
                                                              if (mounted) {
                                                                ScaffoldMessenger.of(
                                                                        context)
                                                                    .showSnackBar(SnackBar(
                                                                        content:
                                                                            Text('Cannot open link ${e.name} and ${e.url}')));
                                                              }
                                                            }
                                                          },
                                                        ))
                                              ],
                                            ),
                                          ),
                                        if (item.links.isEmpty)
                                          const Padding(
                                              padding:
                                                  EdgeInsets.only(top: 8.0))
                                      ],
                                    ),
                                  );
                                }
                              }),
                        ),
                      ),
                      cubit,
                      activeTimelines))
            ],
          );
        },
      ),
    );
  }
}
