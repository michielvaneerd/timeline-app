import 'package:equatable/equatable.dart';
import 'package:timeline/models/settings.dart';
import 'package:timeline/models/timeline.dart';
import 'package:timeline/models/timeline_host.dart';
import 'package:timeline/my_http.dart';
import 'package:timeline/my_store.dart';

class TimelineRepository {
  final MyHttp myHttp;

  const TimelineRepository({required this.myHttp});

  Future<YearAndTimelineItems> getTimelineItems(
      TimelineHost timelineHost, Timeline timeline) async {
    final itemsFromStore = await MyStore.getTimelineItems([timeline.id]);
    if (itemsFromStore.timelineItems.isNotEmpty) {
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

  Future<TimelineAll> getAll() async {
    final settings = await MyStore.getSettings();
    final timelineHosts = await MyStore.getTimelineHosts();
    final timelines = await MyStore.getTimelines();
    Timeline? activeTimeline;
    TimelineHost? activeHost;
    if (settings.activeTimelineId != null) {
      activeTimeline = timelines
          .firstWhere((element) => element.id == settings.activeTimelineId);
      activeHost = timelineHosts
          .firstWhere((element) => element.id == activeTimeline!.hostId);
    }
    return TimelineAll(
        settings: settings,
        activeTimeline: activeTimeline,
        activeHost: activeHost,
        timelineHosts: timelineHosts,
        timelines: timelines);
  }
}

class TimelineAll extends Equatable {
  final Settings settings;
  final Timeline? activeTimeline;
  final TimelineHost? activeHost;
  final List<TimelineHost> timelineHosts;
  final List<Timeline> timelines;

  const TimelineAll(
      {this.activeTimeline,
      required this.settings,
      this.activeHost,
      required this.timelineHosts,
      required this.timelines});
  @override
  List<Object?> get props =>
      [activeTimeline, activeHost, timelineHosts, timelines, settings];
}
