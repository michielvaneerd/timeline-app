import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:timeline/models/settings.dart';
import 'package:timeline/models/timeline.dart';
import 'package:timeline/models/timeline_host.dart';
import 'package:timeline/models/timeline_item.dart';
import 'package:timeline/my_http.dart';
import 'package:timeline/my_store.dart';

class TimelineRepository {
  final MyHttp myHttp;

  const TimelineRepository({required this.myHttp});

  // Future<List<TimelineItem>> getDraftTimelineItems(TimelineHost host) async {
  //   final uri =
  //         '${host.host}/wp-json/mve-timeline/v1/timelines/${timeline.termId}';
  // }

  Future login(TimelineHost host, String username, String plainPassword) async {
    final uri =
        '${host.host}/wp-json/wp/v2/mve_timeline_item?status=draft&_fields=id,title,meta';
    await myHttp.get(uri,
        basicAuthUsername: username, basicAuthPlainPassword: plainPassword);
  }

  Future<YearAndTimelineItems> getTimelineItems(
      List<TimelineHost> timelineHosts, List<Timeline> timelines) async {
    final itemsFromStore =
        await MyStore.getTimelineItems(timelines.map((e) => e.id).toList());

    // Watch out because for some timelines we may have items, but for other we don't, so we have to see for which ones we need to fetch the items.
    // See for which timelines we already have items
    List<int> timelineIdsToFetch = timelines.map((e) => e.id).toList();
    for (final item in itemsFromStore.timelineItems) {
      if (item is TimelineItem) {
        if (timelineIdsToFetch.contains(item.timelineId)) {
          timelineIdsToFetch.remove(item.timelineId);
          if (timelineIdsToFetch.isEmpty) {
            return itemsFromStore;
          }
        }
      }
    }

    final timelinesToFetch = timelineIdsToFetch
        .map((e) => timelines.firstWhere((element) => element.id == e))
        .toList();

    // TODO: requests all in one request (like /timelines/1,2,3)
    // But this must be done per host, dus per host execute query for all timelines at once.
    // Much more performant.
    // final timelineToFetchIdToTermIdMap = {
    //   for (final item in timelinesToFetch) item.id: item.termId
    // };

    final List<Future> fetchFutures = [];
    for (final timeline in timelinesToFetch) {
      final host =
          timelineHosts.firstWhere((element) => element.id == timeline.hostId);
      final uri =
          '${host.host}/wp-json/mve-timeline/v1/timelines/${timeline.termId}';
      fetchFutures.add(myHttp.get(uri));
    }
    final responses = await Future.wait(fetchFutures);
    final List<Future> putFutures = [];
    for (var i = 0; i < responses.length; i++) {
      putFutures.add(MyStore.putTimelineItems(
          timelineHosts
              .firstWhere((element) => element.id == timelinesToFetch[i].hostId)
              .id,
          responses[i],
          timelineId: timelinesToFetch[i].id));
    }
    await Future.wait(putFutures);
    return await MyStore.getTimelineItems(timelines.map((e) => e.id).toList());
  }

  Future<Map<String, dynamic>> getTimelinesFromHostname(String host) async {
    return await myHttp.get('$host/wp-json/mve-timeline/v1/timelines');
  }

  Future<TimelineAll> getAll() async {
    final settings = await MyStore.getSettings();
    final timelineHosts = await MyStore.getTimelineHosts();
    final timelines = await MyStore.getTimelines();
    return TimelineAll(
        settings: settings, timelineHosts: timelineHosts, timelines: timelines);
  }
}

class TimelineAll extends Equatable {
  final Settings settings;
  final List<TimelineHost> timelineHosts;
  final List<Timeline> timelines;

  const TimelineAll(
      {required this.settings,
      required this.timelineHosts,
      required this.timelines});
  @override
  List<Object?> get props => [timelineHosts, timelines, settings];
}
