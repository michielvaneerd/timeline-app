import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeline/my_store.dart';
import 'package:timeline/repositories/timeline_repository.dart';

class MainState extends Equatable {
  final TimelineAll? timelineAll;
  final String? error;
  final bool busy;
  final YearAndTimelineItems? items;

  const MainState(
      {this.timelineAll, this.items, this.error, this.busy = false});
  @override
  List<Object?> get props => [error, busy, timelineAll, items];
}

class MainCubit extends Cubit<MainState> {
  final TimelineRepository timelineRepository;
  MainCubit(this.timelineRepository) : super(const MainState());

  Future checkAtStart({bool withBusy = true, bool refresh = false}) async {
    if (withBusy) {
      emit(const MainState(busy: true));
    }
    TimelineAll timelineAll = await timelineRepository.getAll();
    final activeTimelines = timelineAll.timelines
        .where(
          (element) => element.isActive(),
        )
        .toList();
    YearAndTimelineItems? items;
    if (activeTimelines.isNotEmpty) {
      if (refresh) {
        await MyStore.removeTimelineItems(
            activeTimelines.map((e) => e.id).toList());
      }
      items = await timelineRepository.getTimelineItems(
          timelineAll.timelineHosts, activeTimelines);
      final updatedTimelines = await MyStore.getTimelines();
      timelineAll = TimelineAll(
          settings: timelineAll.settings,
          timelineHosts: timelineAll.timelineHosts,
          timelines: updatedTimelines);
    }
    emit(MainState(timelineAll: timelineAll, items: items));
  }

  void activateTimelines(List<int> timelineIds) async {
    emit(const MainState(busy: true));

    // Needed, so the TimelineItemsScreen will be removed and created, so initState and BlocProvider.create will be called.
    await Future.delayed(const Duration(seconds: 1));

    await MyStore.putActiveTimelineIds(timelineIds);
    checkAtStart(withBusy: false);
  }

  void closeTimeline() async {
    emit(const MainState(busy: true));
    await MyStore.putActiveTimelineIds([]);
    checkAtStart();
  }
}
