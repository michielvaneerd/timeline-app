import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeline/models/timeline.dart';
import 'package:timeline/models/timeline_host.dart';
import 'package:timeline/models/timeline_item.dart';
import 'package:timeline/repositories/timeline_repository.dart';

class DraftItemScreenState extends Equatable {
  final bool busy;
  final String? error;
  final bool completed;

  const DraftItemScreenState(
      {this.busy = false, this.error, this.completed = false});
  @override
  List<Object?> get props => [busy, error, completed];
}

class DraftItemScreenCubit extends Cubit<DraftItemScreenState> {
  final TimelineRepository timelineRepository;
  DraftItemScreenCubit(this.timelineRepository)
      : super(const DraftItemScreenState());

  void update(TimelineHost host, Timeline timeline, TimelineItem item) async {
    emit(const DraftItemScreenState(busy: true));
    await timelineRepository.updateDraftItem(host, timeline, item);
    emit(const DraftItemScreenState(completed: true));
  }

  void create(TimelineHost host, Timeline timeline, TimelineItem item) async {
    emit(const DraftItemScreenState(busy: true));
    await timelineRepository.createDraftItem(host, timeline, item);
    emit(const DraftItemScreenState(completed: true));
  }

  void delete(TimelineHost host, Timeline timeline, TimelineItem item) async {
    emit(const DraftItemScreenState(busy: true));
    await timelineRepository.deleteDraftItem(host, timeline, item);
    emit(const DraftItemScreenState(completed: true));
  }
}
