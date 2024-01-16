import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeline/models/timeline.dart';
import 'package:timeline/models/timeline_host.dart';
import 'package:timeline/models/timeline_item.dart';
import 'package:timeline/my_store.dart';
import 'package:timeline/repositories/timeline_repository.dart';

class TimelineItemsScreenState extends Equatable {
  final YearAndTimelineItems items;
  final bool busy;

  const TimelineItemsScreenState({required this.items, this.busy = false});
  @override
  List<Object?> get props => [items, busy];
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
}
