import 'package:equatable/equatable.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:timeline/models/settings.dart';
import 'package:timeline/models/timeline.dart';
import 'package:timeline/models/timeline_host.dart';
import 'package:timeline/models/timeline_item.dart';

class MyStore {
  static const keySettingsLoadImages = 'load_images';
  static const keySettingsCondensed = 'condensed';
  static const keySettingsImageWidth = 'image_width';
  static const keySettingsThemeMode = 'theme_mode';

  static Database? database;

  static Future init() async {
    database ??= await openDatabase(
      path.join(await getDatabasesPath(), 'timeline.sqlite'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
            'CREATE TABLE settings (id INTEGER PRIMARY KEY, key TEXT, value TEXT)');
        await db.execute(
            'CREATE TABLE hosts (id INTEGER PRIMARY KEY, host TEXT, name TEXT)');
        await db.execute(
            'CREATE TABLE timelines (id INTEGER PRIMARY KEY, term_id INTEGER, name TEXT, description TEXT, host_id INT, active INT)');
        await db.execute(
            'CREATE TABLE items (id INTEGER PRIMARY KEY, timeline_id INTEGER, year INTEGER, year_end INTEGER, intro TEXT, title TEXT, image TEXT, links TEXT, image_source TEXT, image_info TEXT)');
      },
    );
  }

  static Future<Settings> getSettings() async {
    final rows = await database!.query('settings');
    bool loadImages = false;
    bool condensed = false;
    int? imageWidth;
    MyThemeModes themeMode = MyThemeModes.system;
    for (var row in rows) {
      switch (row['key']) {
        case keySettingsLoadImages:
          loadImages = row['value'].toString() == '1';
          break;
        case keySettingsCondensed:
          condensed = row['value'].toString() == '1';
          break;
        case keySettingsImageWidth:
          imageWidth = int.tryParse(row['value'].toString());
          break;
        case keySettingsThemeMode:
          if (row['value'] != null && row['value'].toString().isNotEmpty) {
            themeMode = MyThemeModes.values.byName(row['value'].toString());
          }
          break;
      }
    }
    return Settings(
        loadImages: loadImages,
        condensed: condensed,
        imageWidth: imageWidth,
        themeMode: themeMode);
  }

  static Future putSettings(Settings settings) async {
    await database!.transaction((txn) async {
      final batch = txn.batch();
      batch.delete('settings');
      batch.insert('settings', {
        'key': keySettingsLoadImages,
        'value': settings.loadImages ? '1' : '0'
      });
      batch.insert('settings', {
        'key': keySettingsCondensed,
        'value': settings.condensed ? '1' : '0'
      });
      batch.insert('settings',
          {'key': keySettingsImageWidth, 'value': settings.imageWidth});
      batch.insert('settings',
          {'key': keySettingsThemeMode, 'value': settings.themeMode.value});
      await batch.commit(noResult: true);
    });
  }

  static Future putActiveTimelineIds(List<int> timelineIds) async {
    await database!.transaction((txn) async {
      await txn.update('timelines', {'active': 0});
      if (timelineIds.isNotEmpty) {
        await txn.update('timelines', {'active': 1},
            where: 'id in (${_paramQuestions(timelineIds)})',
            whereArgs: timelineIds);
      }
    });
  }

  static Future<List<TimelineHost>> getTimelineHosts() async {
    final rows = await database!.query('hosts', orderBy: 'host ASC');
    return rows.map((e) => TimelineHost.fromMap(e)).toList();
  }

  static Future<TimelineHost> putTimelineHost(String host, String name) async {
    final id = await database!.insert('hosts', {'host': host, 'name': name});
    return TimelineHost(id: id, host: host, name: name);
  }

  static String _paramQuestions(List params) {
    return params.map((e) => '?').join(',');
  }

  static Future<List<Timeline>> getTimelines({List<int>? hostIds}) async {
    final hostIdsWhere = hostIds != null
        ? (' where host_id in (${_paramQuestions(hostIds)})')
        : '';
    final rows = await database!.rawQuery("""
      select
      timelines.*,
      min(items.year) as year_min,
      max(items.year) as year_max
      from timelines
      left join items on items.timeline_id = timelines.id
      $hostIdsWhere
      group by timelines.id
      order by timelines.name asc
      """, hostIds);
    return rows.map((e) => Timeline.fromMap(e)).toList();
  }

  static Future putTimelinesFromResponse(
      List<Map<String, dynamic>> response, int timelineHostId) async {
    await database!.transaction((txn) async {
      final batch = txn.batch();
      txn.delete('timelines',
          where: 'host_id = ?', whereArgs: [timelineHostId]);
      for (final timeline in response) {
        txn.insert('timelines', {
          'term_id': timeline['term_taxonomy_id'],
          'name': timeline['name'],
          'description': timeline['description'],
          'host_id': timelineHostId,
          'active': 0
        });
      }
      await batch.commit(noResult: true);
    });
  }

  static Future removeTimelineHosts(List<int> hostIds,
      {bool removeHosts = true}) async {
    final timelines = await getTimelines(hostIds: hostIds);
    await database!.transaction((txn) async {
      await removeTimelineItems(timelines.map((e) => e.id).toList(), txn: txn);
      await txn.delete('timelines',
          where: 'host_id IN (${_paramQuestions(hostIds)})',
          whereArgs: hostIds);
      if (removeHosts) {
        await txn.delete('hosts',
            where: 'id IN (${_paramQuestions(hostIds)})', whereArgs: hostIds);
      }
    });
  }

  static Future<YearAndTimelineItems> getTimelineItems(
      List<int> timelineIds) async {
    final rows = await database!.query('items',
        where: 'timeline_id IN (${_paramQuestions(timelineIds)})',
        whereArgs: timelineIds,
        orderBy: 'year ASC');
    final List<TimelineAbstractItem> items = [];
    final Map<int, int> years = {}; // year => index
    var index = 0;
    for (final row in rows) {
      final item = TimelineItem.fromMap(row);
      if (!years.containsKey(item.year)) {
        years[item.year] = index;
        items.add(TimelineYearItem(year: item.year));
        index += 1;
      }
      items.add(item);
      index += 1;
    }
    return YearAndTimelineItems(timelineItems: items, yearIndexes: years);
  }

  static Future putTimelineItems(
      int timelineHostId, int timelineId, Map<String, dynamic> map) async {
    await database!.transaction((txn) async {
      final batch = txn.batch();
      final items = (map['items'] as List);
      for (final item in items) {
        item['timeline_id'] = timelineId;
        txn.insert('items', item);
      }
      await batch.commit(noResult: true);
    });
  }

  static Future removeTimelineItems(List<int> timelineIds,
      {Transaction? txn}) async {
    await (txn ?? database!).delete('items',
        where: 'timeline_id IN (${_paramQuestions(timelineIds)})',
        whereArgs: timelineIds);
  }
}

class YearAndTimelineItems extends Equatable {
  final List<TimelineAbstractItem> timelineItems;
  final Map<int, int> yearIndexes;

  const YearAndTimelineItems(
      {required this.timelineItems, required this.yearIndexes});
  @override
  List<Object?> get props => [timelineItems, yearIndexes];
}
