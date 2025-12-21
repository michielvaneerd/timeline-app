import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scrollview_observer/scrollview_observer.dart';
import 'package:timeline/models/settings.dart';
import 'package:timeline/models/timeline.dart';
import 'package:timeline/models/timeline_item.dart';
import 'package:timeline/my_html_text.dart';
import 'package:timeline/my_image_with_cache.dart';
import 'package:timeline/my_loading_overlay.dart';
import 'package:timeline/my_store.dart';
import 'package:timeline/my_styles.dart';
import 'package:timeline/my_widgets.dart';
import 'package:timeline/repositories/timeline_repository.dart';
import 'package:timeline/screens/content_screen/content_screen.dart';
import 'package:timeline/screens/image_screen/image_screen.dart';
import 'package:timeline/screens/timeline_items_screen/observer_controller_with_lazy_loading.dart';
import 'package:timeline/screens/timeline_items_screen/timeline_items_screen_bloc.dart';
import 'package:timeline/timeline_chart_widget.dart';
import 'package:timeline/utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

// https://github.com/fluttercandies/flutter_scrollview_observer/blob/main/lib/src/common/observer_controller.dart#L334
// https://pub.dev/packages/scroll_to_index

class TimelineItemsWidget extends StatefulWidget {
  final TimelineAll timelineAll;
  final YearAndTimelineItems yearAndTimelineItems;
  final bool showSearch;
  final bool loadImages;
  final void Function() onRefresh;
  const TimelineItemsWidget({
    super.key,
    required this.timelineAll,
    required this.loadImages,
    required this.yearAndTimelineItems,
    required this.onRefresh,
    required this.showSearch,
  });

  @override
  State<TimelineItemsWidget> createState() => _TimelineItemsWidgetState();
}

class _TimelineItemsWidgetState extends State<TimelineItemsWidget> {
  static const _msDisplayScrollLabel = 1000;

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
  final _loadingOverlay = LoadingOverlay();
  int? currentTopVisibleYear;
  String? currentTopVisibleYearName;
  var lastScrollTimestamp = 0;
  var lastScrollToIndexTimestamp = 0;
  late final Timer intervalTimer;
  var displayScrollLabel = false;
  //bool fromScrollToIndexClick = false;
  int? longPressedStartYear;
  int? longPressedEndYear;

  void handleIntervalScrollCheckTimer(Timer timer) {
    if (mounted) {
      if (lastScrollToIndexTimestamp > 0 &&
          DateTime.now().millisecondsSinceEpoch - lastScrollToIndexTimestamp >
              _msDisplayScrollLabel) {
        lastScrollToIndexTimestamp = 0;
      }
      setState(() {
        displayScrollLabel =
            lastScrollToIndexTimestamp == 0 &&
            lastScrollTimestamp > 0 &&
            DateTime.now().millisecondsSinceEpoch - lastScrollTimestamp <
                _msDisplayScrollLabel;
      });
    }
  }

  void handleScrollListener() {
    setState(() {
      longPressedStartYear = null;
      longPressedEndYear = null;
    });
    lastScrollTimestamp = DateTime.now().millisecondsSinceEpoch;
  }

  @override
  void initState() {
    super.initState();
    pixelRatio =
        WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    screenWidth =
        WidgetsBinding
            .instance
            .platformDispatcher
            .views
            .first
            .physicalSize
            .width /
        pixelRatio;
    setState(() {
      currentTopVisibleYear =
          widget.yearAndTimelineItems.yearIndexes.keys.first;
      final firstYearName = widget
          .yearAndTimelineItems
          .timelineItems[widget.yearAndTimelineItems.yearIndexes.values.first +
              1]
          .yearName;
      currentTopVisibleYearName =
          firstYearName != null && firstYearName.isNotEmpty
          ? firstYearName
          : currentTopVisibleYear?.toString();
    });
    intervalTimer = Timer.periodic(
      Duration(seconds: 1),
      handleIntervalScrollCheckTimer,
    );
    observerControllerWithLazyLoading = ObserverControllerWithLazyLoading(
      onBuiltEnd: onBuiltEnd,
      scrollController: scrollController,
    )..init();
    scrollController.addListener(handleScrollListener);
  }

  void onBuiltEnd(List<int> indexes) async {
    setState(() {
      builtIndexes = indexes;
    });
  }

  @override
  void dispose() {
    scrollController.removeListener(handleScrollListener);
    scrollController.dispose();
    yearScrollController.dispose();
    searchController.dispose();
    _loadingOverlay.hide();
    super.dispose();
  }

  void _scrollToIndex(int index) async {
    lastScrollToIndexTimestamp = DateTime.now().millisecondsSinceEpoch;
    await observerControllerWithLazyLoading.scrollToIndex(index);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(
        const Duration(milliseconds: 300),
      ); // needed because images may still be loading so the list view items may get different height
      observerControllerWithLazyLoading.scrollToIndex(index);
    });
  }

  Widget getRefreshIndicatorOrContainer(
    Widget child,
    TimelineItemsScreenCubit cubit,
    List<Timeline> activeTimelines,
  ) {
    if (activeTimelines.length > 1) {
      return Container(child: child);
    } else {
      return RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 1));
          widget.onRefresh();
        },
        child: child,
      );
    }
  }

  Future<Image> _loadImage(TimelineItemImage image) async {
    final response = await http.get(Uri.parse(image.url));
    final bytes = response.bodyBytes;
    return Image.memory(
      bytes,
      cacheWidth: (image.width * pixelRatio).toInt(),
      cacheHeight: (image.height * pixelRatio).toInt(),
      width: image.width.toDouble(),
      height: image.height.toDouble(),
    );
  }

  void _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Cannot open link $url')));
      }
    }
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final activeTimelines = widget.timelineAll.timelines
        .where((element) => element.isActive())
        .toList();
    final timelineColors = {}; // Timeline id => color
    for (final tl in activeTimelines) {
      final intColor = tl.color != null ? Utils.fromHexString(tl.color!) : null;
      timelineColors[tl.id] = intColor != null
          ? Color(intColor)
          : Theme.of(context).colorScheme.tertiaryContainer;
    }
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

          final yearWidth = widget.timelineAll.settings.yearWidth?.toDouble();

          final cubit = BlocProvider.of<TimelineItemsScreenCubit>(context);
          final realItems =
              state.filteredItems ??
              widget
                  .yearAndTimelineItems; // List met hierin: 0 = map met jaar => index van timelineYearItem, 1 = List van alle items (timelineYearItem and timelineItems)
          final yearItems = realItems.timelineItems
              .whereType<TimelineYearItem>()
              .toList();
          final suffixIcon = state.filter.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    cubit.filterItems(
                      '',
                      widget.yearAndTimelineItems,
                      widget.timelineAll.settings,
                    );
                    searchController.clear();
                  },
                  icon: const Icon(Icons.close),
                )
              : null;
          return Stack(
            children: [
              Column(
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
                          cubit.filterItems(
                            value,
                            widget.yearAndTimelineItems,
                            widget.timelineAll.settings,
                          );
                        },
                      ),
                    ),
                  Container(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    height: 90,
                    child: Scrollbar(
                      interactive: true,
                      //thickness: 8,
                      scrollbarOrientation: ScrollbarOrientation.top,
                      controller: yearScrollController,
                      child: ListView.builder(
                        controller: yearScrollController,
                        itemCount: yearItems.length,
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) {
                          final item = yearItems[index];
                          return Container(
                            width: yearWidth,
                            padding: const EdgeInsets.all(12.0),
                            child: Material(
                              color: Theme.of(
                                context,
                              ).colorScheme.inversePrimary,
                              borderRadius: BorderRadius.circular(32),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(32),
                                onTap: () async {
                                  final index =
                                      realItems.yearIndexes[item.year]!;
                                  _scrollToIndex(index);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                  ),
                                  child: Center(
                                    child: Text(
                                      item.getYear(),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: getRefreshIndicatorOrContainer(
                      ListViewObserver(
                        controller: observerControllerWithLazyLoading
                            .listObserverController,
                        onObserve: (result) {
                          final widgetIndex = result.firstChild?.index;
                          if (widgetIndex != null) {
                            final widg = realItems.timelineItems[widgetIndex];
                            if (widg is TimelineYearItem) {
                              setState(() {
                                currentTopVisibleYear = widg.year;
                                currentTopVisibleYearName =
                                    widg.yearName != null &&
                                        widg.yearName!.isNotEmpty
                                    ? widg.yearName
                                    : widg.year.toString();
                              });
                            }
                          }
                          observerControllerWithLazyLoading.onObserve(result);
                        },
                        child: Row(
                          children: [
                            if (widget
                                .timelineAll
                                .settings
                                .displayTimelineChart)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: MyStyles.paddingNormal,
                                ),
                                child: SafeArea(
                                  left: false,
                                  right: false,
                                  child: TimelineChartWidget(
                                    longPressedStartYear: longPressedStartYear,
                                    longPressedEndYear: longPressedEndYear,
                                    orderedYears: yearItems
                                        .map((e) => e.year)
                                        .toList(),
                                    currentYear: currentTopVisibleYear,
                                    onYearClick: (clickedYear) {
                                      final index =
                                          realItems.yearIndexes[clickedYear]!;
                                      _scrollToIndex(index);
                                    },
                                  ),
                                ),
                              ),
                            Expanded(
                              child: Scrollbar(
                                //thickness: 8,
                                interactive: true,
                                controller: scrollController,
                                child: ListView.builder(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  controller: scrollController,
                                  itemCount: realItems.timelineItems.length,
                                  itemBuilder: (context, index) {
                                    final e = realItems.timelineItems[index];
                                    if (e is TimelineYearItem) {
                                      return Card(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primaryContainer,
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            e.getYear(),
                                            style: Theme.of(
                                              context,
                                            ).textTheme.headlineLarge,
                                          ),
                                        ),
                                      );
                                    } else {
                                      final TimelineItem item =
                                          e as TimelineItem;
                                      final timeline = activeTimelines
                                          .firstWhere(
                                            (element) =>
                                                element.id == e.timelineId,
                                          );
                                      final itemImage = item.getImage(
                                        TimelineItemImageSizes.medium,
                                        key2: TimelineItemImageSizes.thumbnail,
                                      );
                                      final fullScreenImage = item.getImage(
                                        TimelineItemImageSizes.full,
                                      );
                                      final loadImage =
                                          itemImage != null &&
                                          observerControllerWithLazyLoading
                                              .shouldActivelyLoad(
                                                index,
                                                builtIndexes,
                                              ) &&
                                          (widget.loadImages ||
                                              imageIndexes.contains(index));
                                      final realImageWidth = itemImage != null
                                          ? (imageWidth > itemImage.width
                                                ? itemImage.width.toDouble()
                                                : imageWidth)
                                          : imageWidth;
                                      final realImageHeight = itemImage != null
                                          ? (itemImage.height *
                                                (realImageWidth /
                                                    itemImage.width))
                                          : 100.0;
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
                                              padding: const EdgeInsets.all(
                                                8.0,
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Flexible(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        if (activeTimelines
                                                                .length >
                                                            1) ...[
                                                          Container(
                                                            decoration: BoxDecoration(
                                                              color:
                                                                  timelineColors[timeline
                                                                      .id],
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    4,
                                                                  ),
                                                            ),
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      8.0,
                                                                  vertical: 2.0,
                                                                ),
                                                            child: Text(
                                                              timeline.name,
                                                              style: Theme.of(context)
                                                                  .textTheme
                                                                  .bodySmall!
                                                                  .copyWith(
                                                                    color: Theme.of(
                                                                      context,
                                                                    ).colorScheme.onTertiaryContainer,
                                                                  ),
                                                            ),
                                                          ),
                                                          const Padding(
                                                            padding:
                                                                EdgeInsets.only(
                                                                  top: 4.0,
                                                                ),
                                                          ),
                                                        ],
                                                        InkWell(
                                                          onTap:
                                                              item.yearEnd !=
                                                                  null
                                                              ? () {
                                                                  setState(() {
                                                                    if (longPressedStartYear !=
                                                                            null &&
                                                                        longPressedStartYear ==
                                                                            item.year) {
                                                                      longPressedStartYear =
                                                                          null;
                                                                      longPressedEndYear =
                                                                          null;
                                                                    } else {
                                                                      longPressedStartYear =
                                                                          item.year;
                                                                      longPressedEndYear =
                                                                          item.yearEnd;
                                                                    }
                                                                  });
                                                                }
                                                              : null,
                                                          child: Text(
                                                            item.title,
                                                            style:
                                                                Theme.of(
                                                                      context,
                                                                    )
                                                                    .textTheme
                                                                    .titleLarge,
                                                          ),
                                                        ),
                                                        Text(
                                                          item.years(),
                                                          style: Theme.of(
                                                            context,
                                                          ).textTheme.bodySmall,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: [
                                                      if (!widget
                                                              .timelineAll
                                                              .settings
                                                              .condensed &&
                                                          !widget.loadImages &&
                                                          itemImage != null)
                                                        InkWell(
                                                          child: Icon(
                                                            color:
                                                                Theme.of(
                                                                      context,
                                                                    )
                                                                    .colorScheme
                                                                    .primary,
                                                            Icons
                                                                .image_outlined,
                                                            size:
                                                                Theme.of(
                                                                      context,
                                                                    )
                                                                    .textTheme
                                                                    .titleLarge
                                                                    ?.fontSize,
                                                          ),
                                                          onTap: () {
                                                            var tmp =
                                                                List<int>.from(
                                                                  imageIndexes,
                                                                );
                                                            if (tmp.contains(
                                                              index,
                                                            )) {
                                                              tmp.remove(index);
                                                            } else {
                                                              tmp.add(index);
                                                            }
                                                            setState(() {
                                                              imageIndexes =
                                                                  tmp;
                                                            });
                                                          },
                                                        ),
                                                      if (item.hasContent)
                                                        InkWell(
                                                          child: Icon(
                                                            color:
                                                                Theme.of(
                                                                      context,
                                                                    )
                                                                    .colorScheme
                                                                    .primary,
                                                            Icons.arrow_outward,
                                                            size:
                                                                Theme.of(
                                                                      context,
                                                                    )
                                                                    .textTheme
                                                                    .titleLarge
                                                                    ?.fontSize,
                                                          ),
                                                          onTap: () => Navigator.of(context).push(
                                                            MaterialPageRoute(
                                                              builder: (context) => ContentScreen(
                                                                onSurfaceColor:
                                                                    Theme.of(
                                                                          context,
                                                                        )
                                                                        .colorScheme
                                                                        .onSurface,
                                                                linkColor:
                                                                    Theme.of(
                                                                          context,
                                                                        )
                                                                        .colorScheme
                                                                        .secondary,
                                                                surfaceColor:
                                                                    Theme.of(
                                                                          context,
                                                                        )
                                                                        .colorScheme
                                                                        .surface,
                                                                timelineHost: widget
                                                                    .timelineAll
                                                                    .timelineHosts
                                                                    .firstWhere(
                                                                      (
                                                                        element,
                                                                      ) =>
                                                                          element
                                                                              .id ==
                                                                          timeline
                                                                              .hostId,
                                                                    ),
                                                                timeline:
                                                                    timeline,
                                                                timelineItem:
                                                                    item,
                                                                settings: widget
                                                                    .timelineAll
                                                                    .settings,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (!widget
                                                    .timelineAll
                                                    .settings
                                                    .condensed &&
                                                item.intro.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.all(
                                                  8.0,
                                                ),
                                                child: MyHtmlText.getRichText(
                                                  item.intro,
                                                  onLinkClicked: ({id, url}) {
                                                    if (id != null) {
                                                      int i = 0;
                                                      for (final t
                                                          in widget
                                                              .yearAndTimelineItems
                                                              .timelineItems) {
                                                        if (t is TimelineItem) {
                                                          // Important to also check for timeline ID, because we can display many different timelines from different hosts
                                                          // so postId is not unique!
                                                          if (t.postId == id &&
                                                              t.timelineId ==
                                                                  item.timelineId) {
                                                            _scrollToIndex(i);
                                                            return;
                                                          }
                                                        }
                                                        i += 1;
                                                      }
                                                    } else if (url != null) {
                                                      _launchUrl(url);
                                                    }
                                                  },
                                                  textStyle: Theme.of(
                                                    context,
                                                  ).textTheme.bodyLarge,
                                                ),
                                              ),

                                            // Load image only if we scroll manually (requestedIndex == -1) or when the index is less than 3 away from requestedIndex
                                            if (!widget
                                                    .timelineAll
                                                    .settings
                                                    .condensed &&
                                                loadImage) ...[
                                              const Padding(
                                                padding: EdgeInsets.only(
                                                  top: 8.0,
                                                ),
                                              ),
                                              Center(
                                                //widthFactor: imageWidth,
                                                child: Column(
                                                  // crossAxisAlignment:
                                                  //     CrossAxisAlignment.stretch,
                                                  children: [
                                                    InkWell(
                                                      onTap:
                                                          fullScreenImage !=
                                                              null
                                                          ? () async {
                                                              // Preload full image, so hero animation goes smooth
                                                              _loadingOverlay
                                                                  .show(
                                                                    context,
                                                                  );
                                                              final image =
                                                                  await _loadImage(
                                                                    fullScreenImage,
                                                                  );
                                                              _loadingOverlay
                                                                  .hide();
                                                              if (context
                                                                  .mounted) {
                                                                Navigator.of(
                                                                  context,
                                                                ).push(
                                                                  MaterialPageRoute(
                                                                    builder:
                                                                        (
                                                                          context,
                                                                        ) => ImageScreen(
                                                                          tag:
                                                                              'image-${item.id}',
                                                                          image:
                                                                              image,
                                                                        ),
                                                                  ),
                                                                );
                                                              }
                                                            }
                                                          : null,
                                                      child: Hero(
                                                        tag: 'image-${item.id}',
                                                        child:
                                                            widget
                                                                .timelineAll
                                                                .settings
                                                                .cachedImages
                                                            ? MyImageWithCache(
                                                                cacheOnly:
                                                                    widget
                                                                            .timelineAll
                                                                            .settings
                                                                            .loadImages ==
                                                                        LoadImages
                                                                            .cachedWhenNotOnWifi &&
                                                                    widget
                                                                        .loadImages,
                                                                dirPath:
                                                                    MyStore.getImageCachePath(),
                                                                uri: itemImage
                                                                    .url,
                                                                width:
                                                                    realImageWidth,
                                                                height:
                                                                    realImageHeight,
                                                                pixelRatio:
                                                                    pixelRatio,
                                                              )
                                                            : Image.network(
                                                                itemImage.url,
                                                                width:
                                                                    realImageWidth,
                                                                height:
                                                                    realImageHeight,
                                                                errorBuilder:
                                                                    (
                                                                      context,
                                                                      error,
                                                                      stackTrace,
                                                                    ) => Placeholder(
                                                                      fallbackHeight:
                                                                          realImageHeight,
                                                                      fallbackWidth:
                                                                          realImageWidth,
                                                                    ),
                                                                cacheWidth:
                                                                    (realImageWidth *
                                                                            pixelRatio)
                                                                        .toInt(),
                                                                cacheHeight:
                                                                    (realImageHeight *
                                                                            pixelRatio)
                                                                        .toInt(),
                                                              ),
                                                      ),
                                                    ),
                                                    if ((item.imageInfo !=
                                                                null &&
                                                            item
                                                                .imageInfo!
                                                                .isNotEmpty) ||
                                                        (item.imageSource !=
                                                                null &&
                                                            item
                                                                .imageSource!
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
                                                                    const EdgeInsets.all(
                                                                      8.0,
                                                                    ),
                                                                child: Align(
                                                                  alignment:
                                                                      Alignment
                                                                          .centerRight,
                                                                  child: Text(
                                                                    item.imageInfo!,
                                                                    style: Theme.of(context)
                                                                        .textTheme
                                                                        .bodySmall!
                                                                        .copyWith(
                                                                          color: Theme.of(
                                                                            context,
                                                                          ).colorScheme.secondary,
                                                                        ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          if (item.imageSource !=
                                                                  null &&
                                                              item
                                                                  .imageSource!
                                                                  .isNotEmpty)
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets.all(
                                                                    8.0,
                                                                  ),
                                                              child: Align(
                                                                alignment: Alignment
                                                                    .centerRight,
                                                                child: InkWell(
                                                                  onTap: () {
                                                                    ScaffoldMessenger.of(
                                                                      context,
                                                                    ).showSnackBar(
                                                                      SnackBar(
                                                                        content:
                                                                            Text(
                                                                              item.imageSource!,
                                                                            ),
                                                                      ),
                                                                    );
                                                                  },
                                                                  child: Text(
                                                                    'Source',
                                                                    style: Theme.of(
                                                                      context,
                                                                    ).textTheme.bodySmall,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                            if (!widget
                                                    .timelineAll
                                                    .settings
                                                    .condensed &&
                                                item.links.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.all(
                                                  8.0,
                                                ),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      myLoc(context).links,
                                                      style: Theme.of(
                                                        context,
                                                      ).textTheme.titleSmall,
                                                    ),
                                                    ...item.links.map(
                                                      (e) => InkWell(
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets.only(
                                                                bottom: 4.0,
                                                              ),
                                                          child: Text(
                                                            e.name,
                                                            style: Theme.of(context)
                                                                .textTheme
                                                                .bodySmall
                                                                ?.copyWith(
                                                                  decoration:
                                                                      TextDecoration
                                                                          .underline,
                                                                ),
                                                          ),
                                                        ),
                                                        onTap: () async {
                                                          _launchUrl(e.url);
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            if (item.links.isEmpty)
                                              const Padding(
                                                padding: EdgeInsets.only(
                                                  top: 8.0,
                                                ),
                                              ),
                                          ],
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      cubit,
                      activeTimelines,
                    ),
                  ),
                ],
              ),
              if (displayScrollLabel &&
                  widget.timelineAll.settings.displayScrollLabel)
                Align(
                  alignment: AlignmentGeometry.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      right: MyStyles.paddingNormal * 2,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                      padding: EdgeInsets.all(MyStyles.paddingNormal),
                      child: Text(
                        currentTopVisibleYearName?.toString() ?? '?',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onTertiary,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
