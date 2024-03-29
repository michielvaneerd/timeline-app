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

  Future<List<TimelineItem>> getDraftTimelineItems(
      TimelineHost host, List<Timeline> timelines) async {
    // To get items from only specific timelines, add: &mve_timeline=9,10
    final uri =
        '${host.host}/wp-json/wp/v2/mve_timeline_item?_fields=id,mve_timeline,meta,modified,title,title_raw&status=draft&order=desc&orderby=modified&per_page=100';
    final password = await _decrypt(host.password);
    final response = await myHttp.get<List>(uri,
        basicAuthUsername: host.username, basicAuthPlainPassword: password);
    return response.map((e) {
      final timelineArr = e['mve_timeline'] as List;
      final timeline = timelineArr.isNotEmpty
          ? timelines
              .firstWhereOrNull((element) => element.termId == timelineArr[0])
          : null;
      return TimelineItem.fromApiMap(e, timeline?.id);
    }).toList();
  }

  Future<String?> _decrypt(String? value) async {
    return value != null ? await MyStore.decrypt(value) : null;
  }

  Future updateDraftItem(
      TimelineHost host, Timeline timeline, TimelineItem item) async {
    final uri = '${host.host}/wp-json/wp/v2/mve_timeline_item/${item.postId}';
    final password = await _decrypt(host.password);
    await myHttp.post(uri, item.toDraftMap(timeline.termId),
        basicAuthUsername: host.username, basicAuthPlainPassword: password);
  }

  Future createDraftItem(
      TimelineHost host, Timeline timeline, TimelineItem item) async {
    final uri = '${host.host}/wp-json/wp/v2/mve_timeline_item';
    final password = await _decrypt(host.password);
    await myHttp.post<Map>(uri, item.toDraftMap(timeline.termId),
        basicAuthUsername: host.username, basicAuthPlainPassword: password);
  }

  Future deleteDraftItem(
      TimelineHost host, Timeline timeline, TimelineItem item) async {
    final uri = '${host.host}/wp-json/wp/v2/mve_timeline_item/${item.postId}';
    final password = await _decrypt(host.password);
    await myHttp.delete(uri,
        basicAuthUsername: host.username, basicAuthPlainPassword: password);
  }

  Future login(TimelineHost host, String username, String plainPassword) async {
    final uri =
        '${host.host}/wp-json/wp/v2/mve_timeline_item?_fields=id,mve_timeline,meta,modified,title,title_raw&status=draft&order=desc&orderby=modified';
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

    final Map<int, Map<int, int>> hostIdTimelineIdsMap =
        {}; // hostid : {timeline.term_id: timelines.id}
    for (final item in timelinesToFetch) {
      final host =
          timelineHosts.firstWhere((element) => element.id == item.hostId);
      if (!hostIdTimelineIdsMap.containsKey(host.id)) {
        hostIdTimelineIdsMap[host.id] = {};
      }
      hostIdTimelineIdsMap[host.id]![item.termId] = item.id;
    }

    final List<Future> fetchFutures = [];

    for (final entry in hostIdTimelineIdsMap.entries) {
      final host =
          timelineHosts.firstWhere((element) => element.id == entry.key);
      final hostTimelineExternalIds = hostIdTimelineIdsMap[host.id]!.keys;
      // final uri =
      //     '${host.host}/wp-json/mve-timeline/v1/timelines/${hostTimelineExternalIds.join(',')}';
      // http://localhost:8000/wp-json/wp/v2/mve_timeline_item?_fields=id,title,mve_timeline,meta&order=desc&orderby=meta.mve_timeline_year&mve_timeline=11,8
      final uri =
          '${host.host}/wp-json/wp/v2/mve_timeline_item?_fields=id,mve_timeline,meta,title,title_raw&mve_timeline=${hostTimelineExternalIds.join(',')}&per_page=100';
      fetchFutures.add(myHttp.getWithPagination(uri));
    }

    final responses = await Future.wait(fetchFutures);
    final List<Future> putFutures = [];
    // Per host we get response back for items of all timelines.
    for (var i = 0; i < responses.length; i++) {
      final hostId = hostIdTimelineIdsMap.keys.elementAt(i);
      putFutures.add(MyStore.putTimelineItems(
          responses[i], hostIdTimelineIdsMap[hostId]!));
    }
    await Future.wait(putFutures);
    return await MyStore.getTimelineItems(timelines.map((e) => e.id).toList());
  }

  Future<List> getTimelinesFromHostname(String host) async {
    return await myHttp.get<List>(
        '$host/wp-json/wp/v2/mve_timeline?_fields=id,description,name,count&mve_timeline_published=1');
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
