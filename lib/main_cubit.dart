import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeline/models/settings.dart';
import 'package:timeline/my_store.dart';
import 'package:timeline/repositories/timeline_repository.dart';

class MainState extends Equatable {
  final TimelineAll? timelineAll;
  final String? error;
  final bool busy;
  final YearAndTimelineItems? items;
  final bool? loadImages;
  final List<ConnectivityResult>? connectivityResult;

  const MainState(
      {this.timelineAll,
      this.items,
      this.error,
      this.busy = false,
      this.connectivityResult,
      this.loadImages});
  @override
  List<Object?> get props => [error, busy, timelineAll, items, loadImages];
}

class MainCubit extends Cubit<MainState> {
  final TimelineRepository timelineRepository;
  MainCubit(this.timelineRepository) : super(const MainState());

  Future checkAtStart({bool withBusy = true, bool refresh = false}) async {
    if (withBusy) {
      emit(const MainState(busy: true));
    }

    TimelineAll timelineAll = await timelineRepository.getAll();
    var loadImages = false;
    List<ConnectivityResult>? connectivityResult;
    switch (timelineAll.settings.loadImages) {
      case LoadImages.always:
        loadImages = true;
        break;
      case LoadImages.never:
        loadImages = false;
        break;
      case LoadImages.wifi:
        connectivityResult = await Connectivity().checkConnectivity();
        loadImages = connectivityResult.contains(ConnectivityResult.wifi);
        break;
      case LoadImages.cachedWhenNotOnWifi:
        connectivityResult = await Connectivity().checkConnectivity();
        loadImages = timelineAll.settings.cachedImages ||
            connectivityResult.contains(ConnectivityResult.wifi);
        break;
    }
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
      try {
        items = await timelineRepository.getTimelineItems(
            timelineAll.timelineHosts, activeTimelines);
      } on SocketException catch (ex) {
        // No internet connection, or host does not exist
        emit(MainState(
            error: ex.message,
            timelineAll: timelineAll,
            loadImages: loadImages));
        return;
      } catch (ex) {
        emit(MainState(
            error: ex.toString(),
            timelineAll: timelineAll,
            loadImages: loadImages));
        return;
      }

      final updatedTimelines = await MyStore.getTimelines();
      timelineAll = TimelineAll(
          settings: timelineAll.settings,
          timelineHosts: timelineAll.timelineHosts,
          timelines: updatedTimelines);
    }
    emit(MainState(
        timelineAll: timelineAll,
        items: items,
        loadImages: loadImages,
        connectivityResult: connectivityResult));
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
