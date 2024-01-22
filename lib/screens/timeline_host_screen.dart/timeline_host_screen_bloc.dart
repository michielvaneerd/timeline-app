import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeline/models/timeline_host.dart';
import 'package:timeline/my_store.dart';
import 'package:timeline/repositories/timeline_repository.dart';

class TimelineHostScreenState extends Equatable {
  final String? error;
  final bool busy;
  final TimelineAll timelineAll;

  const TimelineHostScreenState(
      {this.error, this.busy = false, required this.timelineAll});

  @override
  List<Object?> get props => [error, busy, timelineAll];
}

class TimelineHostScreenCubit extends Cubit<TimelineHostScreenState> {
  final TimelineRepository timelineRepository;
  TimelineHostScreenCubit(TimelineAll timelineAll, this.timelineRepository)
      : super(TimelineHostScreenState(timelineAll: timelineAll));

  Future removeHost(TimelineAll timelineAll, TimelineHost host) async {
    emit(TimelineHostScreenState(timelineAll: timelineAll, busy: true));
    await Future.delayed(const Duration(seconds: 1));
    await MyStore.removeTimelineHosts([host.id]);
    // final all = await timelineRepository.getAll();
    // emit(TimelineHostScreenState(timelineAll: all));
  }

  void refreshHost(TimelineAll timelineAll, TimelineHost host) async {
    emit(TimelineHostScreenState(timelineAll: timelineAll, busy: true));
    await Future.delayed(const Duration(seconds: 1));
    await MyStore.removeTimelineHosts([host.id]);

// TODO: dit is bijna hetzelfde als de hostsCubit, dus sharen of 1 cubit maken.
    try {
      final response =
          await timelineRepository.getTimelinesFromHostname(host.host);
      final timelineHost = await MyStore.putTimelineHost(host.host);
      await MyStore.putTimelinesFromResponse(
          (response['items'] as List)
              .map((e) => e as Map<String, dynamic>)
              .toList(),
          timelineHost.id);
    } catch (ex) {
      final all = await timelineRepository.getAll();
      emit(TimelineHostScreenState(error: ex.toString(), timelineAll: all));
      return;
    }
    final all = await timelineRepository.getAll();
    emit(TimelineHostScreenState(timelineAll: all));
  }
}
