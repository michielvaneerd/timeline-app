import 'package:equatable/equatable.dart';
import 'package:timeline/models/timeline.dart';
import 'package:timeline/models/timeline_host.dart';
import 'package:timeline/models/timeline_item.dart';
import 'package:timeline/my_http.dart';
import 'package:timeline/my_store.dart';

class TimelineRepository {
  final MyHttp myHttp;

  const TimelineRepository({required this.myHttp});

  Future<List<TimelineItem>> getTimelineItems(
      TimelineHost timelineHost, Timeline timeline) async {
    final itemsFromStore = await MyStore.getTimelineItems([timeline.id]);
    if (itemsFromStore.isNotEmpty) {
      return itemsFromStore;
    }
    final uri =
        '${timelineHost.host}/wp-json/mve-timeline/v1/timelines/${timeline.termId}';
    final response = await myHttp.get(uri);
    await MyStore.putTimelineItems(timelineHost.id, timeline.id, response);
    return await MyStore.getTimelineItems([timeline.id]);
  }

  Future<Map<String, dynamic>> getTimelinesFromHostname(String host) async {
    return await myHttp.get('$host/wp-json/mve-timeline/v1/timelines');
  }

  // Future putTimelinesFromResponse(
  //     Map<String, dynamic> response, TimelineHost timelineHost) async {
  //   await MyStore.putTimelinesFromResponse(
  //       (response['items'] as List)
  //           .map((e) => e as Map<String, dynamic>)
  //           .toList(),
  //       timelineHost.id);
  // }

  // Future<List<Timeline>> getTimelines({TimelineHost? timelineHost}) async {
  //   var storedTimelines = await MyStore.getTimelines(
  //       timelineHost != null ? [timelineHost.id] : null);
  //   if (storedTimelines.isEmpty && timelineHost != null) {
  //     // final response = await myHttp.get(
  //     //     '${timelineHost.host}/wp-json/wp/v2/mve_timeline?_fields=id,name,description&hide_empty=1');
  //     final response = await myHttp
  //         .get('${timelineHost.host}/wp-json/mve-timeline/v1/timelines');
  //     await MyStore.putTimelinesFromResponse(
  //         (response['items'] as List)
  //             .map((e) => e as Map<String, dynamic>)
  //             .toList(),
  //         timelineHost.id);
  //     storedTimelines = await MyStore.getTimelines([timelineHost.id]);
  //   }
  //   return storedTimelines;
  // }

  Future<TimelineAll> getAll() async {
    final activeTimelineId = await MyStore.getActiveTimelineId();
    final timelineHosts = await MyStore.getTimelineHosts();
    final timelines = await MyStore.getTimelines();
    Timeline? activeTimeline;
    TimelineHost? activeHost;
    if (activeTimelineId != null) {
      activeTimeline =
          timelines.firstWhere((element) => element.id == activeTimelineId);
      activeHost = timelineHosts
          .firstWhere((element) => element.id == activeTimeline!.hostId);
    }
    return TimelineAll(
        activeTimeline: activeTimeline,
        activeHost: activeHost,
        timelineHosts: timelineHosts,
        timelines: timelines);
  }
}

class TimelineAll extends Equatable {
  final Timeline? activeTimeline;
  final TimelineHost? activeHost;
  final List<TimelineHost> timelineHosts;
  final List<Timeline> timelines;

  const TimelineAll(
      {this.activeTimeline,
      this.activeHost,
      required this.timelineHosts,
      required this.timelines});
  @override
  List<Object?> get props =>
      [activeTimeline, activeHost, timelineHosts, timelines];
}
