import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeline/models/settings.dart';
import 'package:timeline/models/timeline_item.dart';
import 'package:timeline/my_store.dart';
import 'package:timeline/repositories/timeline_repository.dart';

class TimelineItemsScreenState extends Equatable {
  final YearAndTimelineItems? filteredItems;
  final bool busy;
  final String filter;

  const TimelineItemsScreenState(
      {this.filteredItems, this.filter = '', this.busy = false});
  @override
  List<Object?> get props => [busy, filteredItems, filter];
}

class TimelineItemsScreenCubit extends Cubit<TimelineItemsScreenState> {
  final TimelineRepository timelineRepository;
  TimelineItemsScreenCubit(this.timelineRepository)
      : super(const TimelineItemsScreenState());

  Future filterItems(
      String q, YearAndTimelineItems items, Settings settings) async {
    if (q.isEmpty) {
      emit(const TimelineItemsScreenState());
      return;
    }
    final List<TimelineAbstractItem> timelineItems = [];
    var index = 0;
    final Map<int, int> yearMap = {};
    final qToLower = q.toLowerCase();
    for (final item in items.timelineItems) {
      if (item is TimelineItem) {
        if (item.title.toLowerCase().contains(qToLower) ||
            (!settings.condensed &&
                item.intro.toLowerCase().contains(qToLower))) {
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
        filteredItems: YearAndTimelineItems(
            timelineItems: timelineItems, yearIndexes: yearMap)));
  }
}
