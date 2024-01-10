import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeline/my_store.dart';
import 'package:timeline/repositories/timeline_repository.dart';

class MainState extends Equatable {
  final TimelineAll? timelineAll;
  final String? error;
  final bool busy;

  const MainState({this.timelineAll, this.error, this.busy = false});
  @override
  List<Object?> get props => [error, busy, timelineAll];
}

class MainCubit extends Cubit<MainState> {
  final TimelineRepository timelineRepository;
  MainCubit(this.timelineRepository) : super(const MainState());

  Future checkAtStart({bool withBusy = true}) async {
    if (withBusy) {
      emit(const MainState(busy: true));
    }
    final timelineAll = await timelineRepository.getAll();
    emit(MainState(
      timelineAll: timelineAll,
    ));
  }

  void activateTimeline(int timelineId) async {
    emit(const MainState(busy: true));

    // Needed, so the TimelineItemsScreen will be removed and created, so initState and BlocProvider.create will be called.
    await Future.delayed(const Duration(seconds: 1));

    await MyStore.putActiveTimelineId(timelineId);
    checkAtStart(withBusy: false);
  }

  void closeTimeline() async {
    emit(const MainState(busy: true));
    await MyStore.putActiveTimelineId(null);
    checkAtStart();
  }
}
