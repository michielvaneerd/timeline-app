import 'package:flutter/material.dart';
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
import 'package:url_launcher/url_launcher.dart';

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
  final searchController = TextEditingController();
  late final double screenWidth;
  late final double imageWidth;
  late final double pixelRatio;

  @override
  void initState() {
    super.initState();
    pixelRatio =
        WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    screenWidth = WidgetsBinding
            .instance.platformDispatcher.views.first.physicalSize.width /
        pixelRatio;
    //imageWidth = screenWidth >= 320 ? 300 : (screenWidth - 16);
    imageWidth = screenWidth;
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
    searchController.dispose();
  }

  Widget getRefreshIndicatorOrContainer(
      Widget child, TimelineItemsScreenCubit cubit) {
    if (widget.activeTimelines.length > 1) {
      return Container(
        child: child,
      );
    } else {
      return RefreshIndicator(
          onRefresh: () async {
            await Future.delayed(const Duration(seconds: 1));
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
          final realItems = state.filteredItems ?? state.items;
          return Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              if (widget.showSearch)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                        suffixIcon: state.filter.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  cubit.filterItems('', state.items);
                                  searchController.clear();
                                },
                                icon: const Icon(Icons.close))
                            : null,
                        enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.green),
                            borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(
                            borderSide:
                                const BorderSide(color: Colors.green, width: 2),
                            borderRadius: BorderRadius.circular(10))),
                    onChanged: (value) {
                      cubit.filterItems(value, state.items);
                    },
                  ),
                ),
              SizedBox(
                  height: 60,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: realItems.timelineItems
                        .whereType<TimelineYearItem>()
                        .map((e) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Material(
                          //color: Colors.orangeAccent,
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () async {
                              final index = realItems.yearIndexes[e.year]!;
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Center(
                                  child: Text(
                                e.year.toString(),
                                style: Theme.of(context).textTheme.bodyLarge,
                              )),
                            ),
                          ),
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
                            physics: const AlwaysScrollableScrollPhysics(),
                            controller: scrollController,
                            itemCount: realItems.timelineItems.length,
                            itemBuilder: (context, index) {
                              final e = realItems.timelineItems[index];
                              if (e is TimelineYearItem) {
                                return Card(
                                  color: Colors.greenAccent,
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
                                final loadImage = item.image != null &&
                                    observerControllerWithLazyLoading
                                        .shouldActivelyLoad(
                                            index, builtIndexes) &&
                                    (widget.settings.loadImages ||
                                        imageIndexes.contains(index));
                                final yearText = item.year.toString() +
                                    (item.yearEnd != null
                                        ? (' - ${item.yearEnd}')
                                        : '');
                                return Card(
                                  key: observerControllerWithLazyLoading
                                      .getKey(index),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
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
                                            if (!widget.settings.loadImages &&
                                                item.image != null)
                                              InkWell(
                                                child: Icon(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .secondary,
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
                                      if (item.intro.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: MyHtmlText.getRichText(
                                              item.intro,
                                              textStyle: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge),
                                        ),

                                      // Load image only if we scroll manually (requestedIndex == -1) or when the index is less than 3 away from requestedIndex
                                      if (loadImage) ...[
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
                                                //width: imageWidth,
                                                cacheWidth:
                                                    (imageWidth * pixelRatio)
                                                        .toInt(),
                                              ),
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  if (item.imageInfo != null)
                                                    Flexible(
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(8.0),
                                                        child: Align(
                                                          alignment: Alignment
                                                              .centerRight,
                                                          child: Text(
                                                              item.imageInfo!,
                                                              style: Theme.of(
                                                                      context)
                                                                  .textTheme
                                                                  .bodySmall!
                                                                  .copyWith(
                                                                      color: Theme.of(
                                                                              context)
                                                                          .colorScheme
                                                                          .secondary)),
                                                        ),
                                                      ),
                                                    ),
                                                  if (item.imageSource != null)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8.0),
                                                      child: Align(
                                                        alignment: Alignment
                                                            .centerRight,
                                                        child: InkWell(
                                                          onTap: () {
                                                            ScaffoldMessenger
                                                                    .of(context)
                                                                .showSnackBar(SnackBar(
                                                                    content:
                                                                        Text(item
                                                                            .imageSource!)));
                                                          },
                                                          child: Text('Source',
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
                                      if (item.links.isNotEmpty)
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
                                                                  bottom: 4.0),
                                                          child: Text(e.name,
                                                              style: Theme.of(
                                                                      context)
                                                                  .textTheme
                                                                  .bodySmall
                                                                  ?.copyWith(
                                                                      decoration:
                                                                          TextDecoration
                                                                              .underline)),
                                                        ),
                                                        onTap: () async {
                                                          if (!await launchUrl(
                                                              Uri.parse(
                                                                  e.url))) {
                                                            if (mounted) {
                                                              ScaffoldMessenger
                                                                      .of(
                                                                          context)
                                                                  .showSnackBar(
                                                                      SnackBar(
                                                                          content:
                                                                              Text('Cannot open link ${e.name} and ${e.url}')));
                                                            }
                                                          }
                                                        },
                                                      ))
                                                  .toList()
                                            ],
                                          ),
                                        ),
                                      if (item.links.isEmpty)
                                        const Padding(
                                            padding: EdgeInsets.only(top: 8.0))
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
