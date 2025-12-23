import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeline/models/timeline.dart';
import 'package:timeline/models/timeline_host.dart';
import 'package:timeline/my_exception.dart';
import 'package:timeline/my_store.dart';
import 'package:timeline/repositories/timeline_repository.dart';
import 'package:collection/collection.dart';

class TimelineHostsScreenState extends Equatable {
  final MyException? exception;
  final bool busy;
  final TimelineAll timelineAll;
  final bool showAddHostOnStart;
  final Map<int, bool>? timelineChanged;

  const TimelineHostsScreenState({
    this.exception,
    this.busy = false,
    required this.timelineAll,
    this.timelineChanged,
    this.showAddHostOnStart = false,
  });

  TimelineHostsScreenState copyWith({
    bool showAddHostOnStart = false,
    MyException? exception,
    bool removeException = false,
    bool busy = false,
    TimelineAll? timelineAll,
    Map<int, bool>? timelineChanged,
  }) {
    return TimelineHostsScreenState(
      showAddHostOnStart: showAddHostOnStart,
      timelineChanged: timelineChanged ?? this.timelineChanged,
      busy: busy,
      timelineAll: timelineAll ?? this.timelineAll,
      exception: removeException ? null : (exception ?? this.exception),
    );
  }

  @override
  List<Object?> get props => [
    exception,
    busy,
    timelineAll,
    showAddHostOnStart,
    timelineChanged,
  ];
}

class TimelineHostsScreenCubit extends Cubit<TimelineHostsScreenState> {
  final TimelineRepository timelineRepository;
  TimelineHostsScreenCubit({
    required this.timelineRepository,
    required TimelineAll timelineAll,
  }) : super(TimelineHostsScreenState(timelineAll: timelineAll));

  void refresh() async {
    emit(state.copyWith(busy: true, removeException: true));
    await Future.delayed(const Duration(seconds: 1));
    try {
      final all = await timelineRepository.getAll();
      emit(state.copyWith(timelineAll: all, removeException: true));
    } on MyException catch (ex) {
      emit(state.copyWith(exception: ex));
    }
  }

  void removeHosts(List<int> hostIds) async {
    emit(state.copyWith(busy: true));
    await MyStore.removeTimelineHosts(hostIds, removeHosts: true);
    final all = await timelineRepository.getAll();
    emit(TimelineHostsScreenState(timelineAll: all));
  }

  // Called at the start when opening the screen.
  void showAddHostOnStart({
    bool show = false,
    required TimelineAll timelineAll,
  }) async {
    // TODO: Inside try...catch!
    emit(state.copyWith(busy: true));
    await Future.delayed(Duration(seconds: 1));
    final List<Future> futures = [];
    for (final h in timelineAll.timelineHosts) {
      futures.add(timelineRepository.getTimelinesFromHostname(h.host));
    }
    final futureResponses = await Future.wait(futures);
    var hostIndex = 0;
    final Map<int, bool> timelineChanged = {};
    for (final host in timelineAll.timelineHosts) {
      final hostResponse = futureResponses[hostIndex];
      for (final Map<String, dynamic> map in hostResponse) {
        final termId = map['id'];
        final lastModifiedAt = map['last_modified_at'];
        final storedTimeline = timelineAll.timelines.firstWhereOrNull(
          (e) => e.hostId == host.id && e.termId == termId,
        );
        if (storedTimeline != null &&
            storedTimeline.lastModifiedAt != lastModifiedAt) {
          timelineChanged[storedTimeline.id] = true;
        }
      }
      hostIndex += 1;
    }

    emit(
      state.copyWith(
        showAddHostOnStart: show,
        timelineChanged: timelineChanged,
      ),
    );
  }

  void refreshHost(TimelineAll timelineAll, TimelineHost host) async {
    emit(state.copyWith(busy: true, removeException: true));
    await Future.delayed(const Duration(seconds: 1));

    try {
      final response = await timelineRepository.getTimelinesFromHostname(
        host.host,
      );
      await MyStore.removeTimelineHosts([host.id], removeHosts: false);
      await MyStore.putTimelinesFromResponse(
        response.map((e) => e as Map<String, dynamic>).toList(),
        host.id,
      );
      final all = await timelineRepository.getAll();
      Map<int, bool> newTimelineChanged = {};
      if (state.timelineChanged != null) {
        for (final t in all.timelines) {
          if (t.hostId != host.id && state.timelineChanged!.containsKey(t.id)) {
            newTimelineChanged[t.id] = true;
          }
        }
      }
      emit(
        state.copyWith(timelineAll: all, timelineChanged: newTimelineChanged),
      );
    } on SocketException {
      final all = await timelineRepository.getAll();
      emit(
        state.copyWith(
          exception: MyException(type: MyExceptionType.internetConnection),
          timelineAll: all,
        ),
      );
    } catch (ex) {
      final all = await timelineRepository.getAll();
      emit(
        state.copyWith(
          exception: MyException(type: MyExceptionType.unknown),
          timelineAll: all,
        ),
      );
    }
  }

  void updateTimelineColor({required Timeline timeline, String? color}) async {
    await MyStore.updateTimelineColor(timeline.id, color);
    final all = await timelineRepository.getAll();
    emit(state.copyWith(timelineAll: all));
  }

  void login(
    TimelineAll timelineAll,
    TimelineHost host,
    String username,
    String plainPassword,
  ) async {
    // Make request to see we can connect and if true, store credentials.
    emit(TimelineHostsScreenState(busy: true, timelineAll: timelineAll));
    await Future.delayed(const Duration(seconds: 1));
    try {
      await timelineRepository.login(host, username, plainPassword);
      await MyStore.updateTimelineHost(host.id, username, plainPassword);
      final all = await timelineRepository.getAll();
      emit(state.copyWith(timelineAll: all));
    } catch (ex) {
      emit(
        state.copyWith(exception: MyException(type: MyExceptionType.unknown)),
      );
    }
  }

  Future logout(TimelineAll timelineAll, TimelineHost host) async {
    await MyStore.updateTimelineHost(host.id, null, null);
    final all = await timelineRepository.getAll();
    emit(TimelineHostsScreenState(timelineAll: all));
  }

  void addHost(
    String name,
    String host,
    TimelineAll timelineAll, {
    String? username,
    String? plainPassword,
  }) async {
    emit(state.copyWith(busy: true, removeException: true));
    final currentHosts = await MyStore.getTimelineHosts();
    final existingHost = currentHosts.firstWhereOrNull(
      (element) => element.host == host,
    );
    if (existingHost != null) {
      emit(
        state.copyWith(
          exception: MyException(type: MyExceptionType.duplicateHost),
        ),
      );
      return;
    }

    try {
      final response = await timelineRepository.getTimelinesFromHostname(host);
      final timelineHost = await MyStore.putTimelineHost(
        host,
        name,
        username,
        plainPassword,
      );
      await MyStore.putTimelinesFromResponse(
        response.map((e) => e as Map<String, dynamic>).toList(),
        timelineHost.id,
      );
      final all = await timelineRepository.getAll();
      emit(TimelineHostsScreenState(timelineAll: all));
    } on MyException catch (ex) {
      emit(state.copyWith(exception: ex));
    } catch (ex) {
      emit(
        state.copyWith(exception: MyException(type: MyExceptionType.unknown)),
      );
    }
  }
}
