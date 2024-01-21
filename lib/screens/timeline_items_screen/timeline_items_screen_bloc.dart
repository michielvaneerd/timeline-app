import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeline/models/timeline.dart';
import 'package:timeline/models/timeline_host.dart';
import 'package:timeline/models/timeline_item.dart';
import 'package:timeline/my_store.dart';
import 'package:timeline/repositories/timeline_repository.dart';

class TimelineItemsScreenState extends Equatable {
  final YearAndTimelineItems items;
  final YearAndTimelineItems? filteredItems;
  final bool busy;
  final String filter;

  const TimelineItemsScreenState(
      {required this.items,
      this.filteredItems,
      this.filter = '',
      this.busy = false});
  @override
  List<Object?> get props => [items, busy, filteredItems, filter];
}

class TimelineItemsScreenCubit extends Cubit<TimelineItemsScreenState> {
  final TimelineRepository timelineRepository;
  TimelineItemsScreenCubit(this.timelineRepository)
      : super(const TimelineItemsScreenState(
            items: YearAndTimelineItems(timelineItems: [], yearIndexes: {})));

  Future getItems(List<TimelineHost> timelineHosts, List<Timeline> timelines,
      {bool refresh = false}) async {
    emit(const TimelineItemsScreenState(
        items: YearAndTimelineItems(timelineItems: [], yearIndexes: {}),
        busy: true));
    if (refresh) {
      await MyStore.removeTimelineItems(timelines.map((e) => e.id).toList());
    }
    final items =
        await timelineRepository.getTimelineItems(timelineHosts, timelines);
    emit(TimelineItemsScreenState(items: items));
  }

  Future filterItems(String q, YearAndTimelineItems items) async {
    if (q.isEmpty) {
      emit(TimelineItemsScreenState(items: items));
      return;
    }
    final List<TimelineAbstractItem> timelineItems = [];
    var index = 0;
    final Map<int, int> yearMap = {};
    final qToLower = q.toLowerCase();
    for (final item in items.timelineItems) {
      if (item is TimelineItem) {
        if (item.title.toLowerCase().contains(qToLower) ||
            (item.intro.toLowerCase().contains(qToLower))) {
          if (!yearMap.containsKey(item.year)) {
            yearMap[item.year] = index;
            timelineItems.add(TimelineYearItem(year: item.year));
            index += 1;
          }
          timelineItems.add(item);
          index += 1;
        }
      }
    }
    emit(TimelineItemsScreenState(
        filter: q,
        items: items,
        filteredItems: YearAndTimelineItems(
            timelineItems: timelineItems, yearIndexes: yearMap)));
  }
}
