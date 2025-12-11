import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeline/models/timeline_host.dart';
import 'package:timeline/my_exception.dart';
import 'package:timeline/my_store.dart';
import 'package:timeline/repositories/timeline_repository.dart';
import 'package:collection/collection.dart';

class TimelineHostsScreenState extends Equatable {
  final MyException? exception;
  final bool busy;
  final TimelineAll? timelineAll;
  final bool showAddHostOnStart;

  const TimelineHostsScreenState({
    this.exception,
    this.busy = false,
    this.timelineAll,
    this.showAddHostOnStart = false,
  });

  TimelineHostsScreenState copyWith({
    bool showAddHostOnStart = false,
    MyException? exception,
    bool removeException = false,
    bool busy = false,
    TimelineAll? timelineAll,
  }) {
    return TimelineHostsScreenState(
      showAddHostOnStart: showAddHostOnStart,
      busy: busy,
      timelineAll: timelineAll ?? this.timelineAll,
      exception: removeException ? null : (exception ?? this.exception),
    );
  }

  @override
  List<Object?> get props => [exception, busy, timelineAll, showAddHostOnStart];
}

class TimelineHostsScreenCubit extends Cubit<TimelineHostsScreenState> {
  final TimelineRepository timelineRepository;
  TimelineHostsScreenCubit(this.timelineRepository)
    : super(const TimelineHostsScreenState());

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

  void removeHosts(TimelineAll timelineAll, List<int> hostIds) async {
    emit(const TimelineHostsScreenState(busy: true));
    await Future.delayed(const Duration(seconds: 1));

    await MyStore.removeTimelineHosts(hostIds, removeHosts: true);
    final all = await timelineRepository.getAll();
    emit(TimelineHostsScreenState(timelineAll: all));
  }

  void showAddHostOnStart(bool show) async {
    if (show) {
      await Future.delayed(const Duration(milliseconds: 400));
      emit(const TimelineHostsScreenState(showAddHostOnStart: true));
    }
  }

  void refreshHost(TimelineAll timelineAll, TimelineHost host) async {
    emit(state.copyWith(busy: true, removeException: true));
    await Future.delayed(const Duration(seconds: 1));
    await MyStore.removeTimelineHosts([host.id], removeHosts: false);

    try {
      final response = await timelineRepository.getTimelinesFromHostname(
        host.host,
      );
      await MyStore.putTimelinesFromResponse(
        response.map((e) => e as Map<String, dynamic>).toList(),
        host.id,
      );
      final all = await timelineRepository.getAll();
      emit(state.copyWith(timelineAll: all));
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
    } catch (ex) {
      emit(
        state.copyWith(exception: MyException(type: MyExceptionType.unknown)),
      );
    }
  }
}
