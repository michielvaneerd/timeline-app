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

  const TimelineHostsScreenState(
      {this.error, this.busy = false, this.timelineAll});

  @override
  List<Object?> get props => [error, busy, timelineAll];
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

  void refreshHost(TimelineAll timelineAll, TimelineHost host) async {
    emit(TimelineHostsScreenState(timelineAll: timelineAll, busy: true));
    await Future.delayed(const Duration(seconds: 1));
    await MyStore.removeTimelineHosts([host.id], removeHosts: false);

    try {
      final response =
          await timelineRepository.getTimelinesFromHostname(host.host);
      await MyStore.putTimelinesFromResponse(
          (response['items'] as List)
              .map((e) => e as Map<String, dynamic>)
              .toList(),
          host.id);
    } catch (ex) {
      final all = await timelineRepository.getAll();
      emit(TimelineHostsScreenState(error: ex.toString(), timelineAll: all));
      return;
    }
    final all = await timelineRepository.getAll();
    emit(TimelineHostsScreenState(timelineAll: all));
  }

  void addHost(String host, String name, TimelineAll timelineAll) async {
    if (host.isEmpty) {
      emit(const TimelineHostsScreenState(error: 'Invalid host'));
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
      final timelineHost = await MyStore.putTimelineHost(host, name);
      await MyStore.putTimelinesFromResponse(
          (response['items'] as List)
              .map((e) => e as Map<String, dynamic>)
              .toList(),
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
