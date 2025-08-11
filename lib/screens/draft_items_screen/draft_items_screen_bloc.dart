import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeline/models/timeline.dart';
import 'package:timeline/models/timeline_host.dart';
import 'package:timeline/models/timeline_item.dart';
import 'package:timeline/repositories/timeline_repository.dart';

class DraftItemsScreenState extends Equatable {
  final bool busy;
  final String? error;
  final List<TimelineItem>? items;

  const DraftItemsScreenState({this.error, this.busy = false, this.items});
  @override
  List<Object?> get props => [busy, error, items];
}

class DraftItemsScreenCubit extends Cubit<DraftItemsScreenState> {
  final TimelineRepository timelineRepository;
  DraftItemsScreenCubit(this.timelineRepository)
      : super(const DraftItemsScreenState());

  void getItems(TimelineHost timelineHost, List<Timeline> timelines) async {
    emit(const DraftItemsScreenState(busy: true));
    //await Future.delayed(const Duration(seconds: 1));
    final items =
        await timelineRepository.getDraftTimelineItems(timelineHost, timelines);
    emit(DraftItemsScreenState(items: items));
  }
}
