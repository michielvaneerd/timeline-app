import 'package:equatable/equatable.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:timeline/models/settings.dart';
import 'package:timeline/models/timeline.dart';
import 'package:timeline/models/timeline_host.dart';
import 'package:timeline/models/timeline_item.dart';
import 'package:timeline/my_crypt.dart';

class MyStore {
  static const keySettingsLoadImages = 'load_images';
  static const keySettingsCondensed = 'condensed';
  static const keySettingsImageWidth = 'image_width';
  static const keySettingsThemeMode = 'theme_mode';

  static const keySecureStorageKey = 'key';

  static late final String _secretKey;

  static Database? _database;
  static const FlutterSecureStorage _flutterSecureStorage =
      FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions:
              IOSOptions(accessibility: KeychainAccessibility.first_unlock));
  static final MyCrypt _myCrypt = MyCrypt();

  static Future init() async {
    // 1) Get or create secret key
    final secretKey =
        await _flutterSecureStorage.read(key: keySecureStorageKey);
    if (secretKey == null) {
      _secretKey = await _myCrypt.generateSecretKey();
      await _flutterSecureStorage.write(
          key: keySecureStorageKey, value: _secretKey);
    } else {
      _secretKey = secretKey;
    }
    // 2) Get or create database
    _database ??= await openDatabase(
      path.join(await getDatabasesPath(), 'timeline.sqlite'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
            'CREATE TABLE settings (id INTEGER PRIMARY KEY, key TEXT, value TEXT)');
        await db.execute(
            'CREATE TABLE hosts (id INTEGER PRIMARY KEY, host TEXT, name TEXT, username TEXT, password TEXT)');
        await db.execute(
            'CREATE TABLE timelines (id INTEGER PRIMARY KEY, term_id INTEGER, name TEXT, description TEXT, host_id INT, active INT)');
        await db.execute(
            'CREATE TABLE items (id INTEGER PRIMARY KEY, timeline_id INTEGER, year INTEGER, year_end INTEGER, intro TEXT, title TEXT, image TEXT, links TEXT, image_source TEXT, image_info TEXT)');
      },
    );
  }

  static Future<Settings> getSettings() async {
    final rows = await _database!.query('settings');
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
    await _database!.transaction((txn) async {
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
    await _database!.transaction((txn) async {
      await txn.update('timelines', {'active': 0});
      if (timelineIds.isNotEmpty) {
        await txn.update('timelines', {'active': 1},
            where: 'id in (${_paramQuestions(timelineIds)})',
            whereArgs: timelineIds);
      }
    });
  }

  static Future<List<TimelineHost>> getTimelineHosts() async {
    final rows = await _database!.query('hosts', orderBy: 'host ASC');
    return rows.map((e) => TimelineHost.fromMap(e)).toList();
  }

  static Future updateTimelineHost(
      int id, String? username, String? plainPassword) async {
    await _database!.update(
        'hosts', {'username': username, 'password': plainPassword},
        where: 'id = ?', whereArgs: [id]);
  }

  static Future<TimelineHost> putTimelineHost(
      String host, String name, String? username, String? plainPassword) async {
    // final password = plainPassword != null
    //     ? (await _myCrypt.encrypt(plainPassword, _secretKey))
    //     : null;
    final id = await _database!.insert('hosts', {
      'host': host,
      'name': name,
      'username': username,
      'password': plainPassword
    });
    return TimelineHost(id: id, host: host, name: name);
  }

  static String _paramQuestions(List params) {
    return params.map((e) => '?').join(',');
  }

  static Future<List<Timeline>> getTimelines({List<int>? hostIds}) async {
    final hostIdsWhere = hostIds != null
        ? (' where host_id in (${_paramQuestions(hostIds)})')
        : '';
    final rows = await _database!.rawQuery("""
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
    await _database!.transaction((txn) async {
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
    await _database!.transaction((txn) async {
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
    final rows = await _database!.query('items',
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

  static Future putTimelineItems(int timelineHostId, Map<String, dynamic> map,
      {int? timelineId}) async {
    await _database!.transaction((txn) async {
      final batch = txn.batch();
      final items = (map['items'] as List);
      for (Map<String, Object?> item in items) {
        // TODO:
        // We get 'term_taxonomy_id' but we want to have 'timeline_id', the 'timeline_id' is the client ID (not known on the server)
        // So we have to map the 'term_taxonomy_id' to our internal id here.
        // NO this is wrong: we need to set our internal timeline id! And not the backend ID (because as we can get mutliple hosts, this is not unique)
        // if (item.containsKey('term_taxonomy_id')) {
        //   item['timeline_id'] = item['term_taxonomy_id'];
        //   item.remove('term_taxonomy_id');
        // }
        //else {
        //
        //}
        if (item.containsKey('term_taxonomy_id')) {
          item.remove(
              'term_taxonomy_id'); // For now, later we can map this to our internal timeline id.
        }
        if (timelineId != null) {
          item['timeline_id'] = timelineId;
        }
        txn.insert('items', item);
      }
      await batch.commit(noResult: true);
    });
  }

  static Future removeTimelineItems(List<int> timelineIds,
      {Transaction? txn}) async {
    await (txn ?? _database!).delete('items',
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
