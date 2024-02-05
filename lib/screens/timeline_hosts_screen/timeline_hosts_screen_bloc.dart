import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeline/models/timeline_host.dart';
import 'package:timeline/my_store.dart';
import 'package:timeline/repositories/timeline_repository.dart';
import 'package:collection/collection.dart';

class TimelineHostsScreenState extends Equatable {
  final String? error;
  final bool busy;
  final TimelineAll? timelineAll;
  final bool showAddHostOnStart;

  const TimelineHostsScreenState(
      {this.error,
      this.busy = false,
      this.timelineAll,
      this.showAddHostOnStart = false});

  TimelineHostsScreenState copyWith(
      {bool? showAddHostOnStart,
      String? error,
      bool? busy,
      TimelineAll? timelineAll}) {
    return TimelineHostsScreenState(
        showAddHostOnStart: showAddHostOnStart ?? this.showAddHostOnStart,
        busy: busy ?? this.busy,
        timelineAll: timelineAll ?? this.timelineAll,
        error: error ?? this.error);
  }

  @override
  List<Object?> get props => [error, busy, timelineAll, showAddHostOnStart];
}

class TimelineHostsScreenCubit extends Cubit<TimelineHostsScreenState> {
  final TimelineRepository timelineRepository;
  TimelineHostsScreenCubit(this.timelineRepository)
      : super(const TimelineHostsScreenState());

  void refresh() async {
    emit(const TimelineHostsScreenState(busy: true));
    await Future.delayed(const Duration(seconds: 1));
    final all = await timelineRepository.getAll();
    emit(TimelineHostsScreenState(timelineAll: all));
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
    emit(TimelineHostsScreenState(timelineAll: timelineAll, busy: true));
    await Future.delayed(const Duration(seconds: 1));
    await MyStore.removeTimelineHosts([host.id], removeHosts: false);

    try {
      final response =
          await timelineRepository.getTimelinesFromHostname(host.host);
      await MyStore.putTimelinesFromResponse(
          response.map((e) => e as Map<String, dynamic>).toList(), host.id);
    } on SocketException catch (ex) {
      final all = await timelineRepository.getAll();
      emit(TimelineHostsScreenState(error: ex.message, timelineAll: all));
      return;
    } catch (ex) {
      final all = await timelineRepository.getAll();
      emit(TimelineHostsScreenState(error: ex.toString(), timelineAll: all));
      return;
    }
    final all = await timelineRepository.getAll();
    emit(TimelineHostsScreenState(timelineAll: all));
  }

  void login(TimelineAll timelineAll, TimelineHost host, String username,
      String plainPassword) async {
    // Make request to see we can connect and if true, store credentials.
    emit(TimelineHostsScreenState(busy: true, timelineAll: timelineAll));
    await Future.delayed(const Duration(seconds: 1));
    try {
      await timelineRepository.login(host, username, plainPassword);
      await MyStore.updateTimelineHost(host.id, username, plainPassword);
      final all = await timelineRepository.getAll();
      emit(TimelineHostsScreenState(timelineAll: all));
    } catch (ex) {
      emit(TimelineHostsScreenState(
          error: 'Error loging in', timelineAll: timelineAll));
    }
  }

  Future logout(TimelineAll timelineAll, TimelineHost host) async {
    await MyStore.updateTimelineHost(host.id, null, null);
    final all = await timelineRepository.getAll();
    emit(TimelineHostsScreenState(timelineAll: all));
  }

  void addHost(String name, String host, TimelineAll timelineAll,
      {String? username, String? plainPassword}) async {
    if (host.isEmpty) {
      emit(TimelineHostsScreenState(
          error: 'Invalid host', timelineAll: timelineAll));
      return;
    }
    emit(const TimelineHostsScreenState(busy: true));
    final currentHosts = await MyStore.getTimelineHosts();
    final existingHost =
        currentHosts.firstWhereOrNull((element) => element.host == host);
    if (existingHost != null) {
      emit(TimelineHostsScreenState(
          error: 'Host already exists', timelineAll: timelineAll));
      return;
    }

    try {
      final response = await timelineRepository.getTimelinesFromHostname(host);
      final timelineHost =
          await MyStore.putTimelineHost(host, name, username, plainPassword);
      await MyStore.putTimelinesFromResponse(
          response.map((e) => e as Map<String, dynamic>).toList(),
          timelineHost.id);
    } catch (ex) {
      emit(TimelineHostsScreenState(error: ex.toString()));
      return;
    }

    //await timelineRepository.getTimelines(timelineHost: timelineHost);
    final all = await timelineRepository.getAll();
    emit(TimelineHostsScreenState(timelineAll: all));
  }
}
