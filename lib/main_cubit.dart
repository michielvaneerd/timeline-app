import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeline/models/settings.dart';
import 'package:timeline/my_exception.dart';
import 'package:timeline/my_store.dart';
import 'package:timeline/repositories/timeline_repository.dart';
import 'package:timeline/utils.dart';

class MainState extends Equatable {
  final TimelineAll? timelineAll;
  final MyException? exception;
  final bool busy;
  final YearAndTimelineItems? items;
  final bool? loadImages;

  const MainState({
    this.timelineAll,
    this.items,
    this.exception,
    this.busy = false,
    this.loadImages,
  });

  MainState copyWith({
    TimelineAll? timelineAll,
    bool busy = false,
    bool removeException = false,
    MyException? exception,
    YearAndTimelineItems? items,
    bool? loadImages,
  }) {
    return MainState(
      timelineAll: timelineAll ?? this.timelineAll,
      busy: busy,
      exception: removeException ? null : (exception ?? this.exception),
      items: items ?? this.items,
      loadImages: loadImages ?? this.loadImages,
    );
  }

  @override
  List<Object?> get props => [exception, busy, timelineAll, items, loadImages];
}

class MainCubit extends Cubit<MainState> {
  final TimelineRepository timelineRepository;
  MainCubit(this.timelineRepository) : super(const MainState());

  Future checkAtStart({bool withBusy = true, bool refresh = false}) async {
    if (withBusy) {
      emit(state.copyWith(busy: true, removeException: true));
    }

    TimelineAll timelineAll = await timelineRepository.getAll();
    var loadImages = false;
    final connectivityResults = await Connectivity().checkConnectivity();
    switch (timelineAll.settings.loadImages) {
      case LoadImages.always:
        loadImages = true;
        break;
      case LoadImages.never:
        loadImages = false;
        break;
      case LoadImages.wifi:
        loadImages = Utils.isOnWifiOrEthernet(connectivityResults);
        break;
      case LoadImages.cachedWhenNotOnWifi:
        loadImages =
            timelineAll.settings.cachedImages ||
            Utils.isOnWifiOrEthernet(connectivityResults);
        break;
    }
    final activeTimelines = timelineAll.timelines
        .where((element) => element.isActive())
        .toList();
    YearAndTimelineItems? items;
    if (activeTimelines.isNotEmpty) {
      if (refresh) {
        await MyStore.removeTimelineItems(
          activeTimelines.map((e) => e.id).toList(),
        );
      }
      try {
        items = await timelineRepository.getTimelineItems(
          timelineAll.timelineHosts,
          activeTimelines,
        );
      } on SocketException {
        emit(
          state.copyWith(
            exception: MyException(type: MyExceptionType.internetConnection),
            timelineAll: timelineAll,
            loadImages: loadImages,
          ),
        );
        return;
      } catch (ex) {
        emit(
          state.copyWith(
            exception: MyException(type: MyExceptionType.unknown),
            timelineAll: timelineAll,
            loadImages: loadImages,
          ),
        );
        return;
      }

      final updatedTimelines = await MyStore.getTimelines();
      timelineAll = TimelineAll(
        settings: timelineAll.settings,
        timelineHosts: timelineAll.timelineHosts,
        timelines: updatedTimelines,
      );
    }
    emit(
      state.copyWith(
        timelineAll: timelineAll,
        items: items,
        loadImages: loadImages,
      ),
    );
  }

  void activateTimelines(List<int> timelineIds) async {
    emit(state.copyWith(busy: true, removeException: true));

    // Needed, so the TimelineItemsScreen will be removed and created, so initState and BlocProvider.create will be called.
    await Future.delayed(const Duration(seconds: 1));

    await MyStore.putActiveTimelineIds(timelineIds);
    checkAtStart(withBusy: false);
  }

  void closeTimeline() async {
    emit(state.copyWith(busy: true, removeException: true));
    await MyStore.putActiveTimelineIds([]);
    checkAtStart();
  }
}
