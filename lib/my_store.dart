import 'dart:io';

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:timeline/models/settings.dart';
import 'package:timeline/models/timeline.dart';
import 'package:timeline/models/timeline_host.dart';
import 'package:timeline/models/timeline_item.dart';
import 'package:timeline/my_crypt.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

/// Class that handles the local storage.
class MyStore {
  static const keySettingsLoadImages = 'load_images';
  static const keySettingsCondensed = 'condensed';
  static const keySettingsImageWidth = 'image_width';
  static const keySettingsYearWidth = 'year_width';
  static const keySettingsThemeMode = 'theme_mode';
  static const keySettingsCachedImages = 'cached_images';
  static const keySettingsDisplayTimelineChart = 'display_timeline_chart';

  static const keySecureStorageKey = 'key';
  static const _dbVersion = 1;

  static late final String _secretKey;
  static late final String _imageCachePath;

  static Database? _database;
  static const FlutterSecureStorage _flutterSecureStorage =
      FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
        iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
      );
  static final MyCrypt _myCrypt = MyCrypt();

  static Future init() async {
    String? secretKey;
    try {
      secretKey = await _flutterSecureStorage.read(key: keySecureStorageKey);
    } catch (ex) {
      await Future.delayed(Duration(seconds: 1));
      secretKey = await _flutterSecureStorage.read(key: keySecureStorageKey);
    }

    if (secretKey == null) {
      _secretKey = await _myCrypt.generateSecretKey();
      await _flutterSecureStorage.write(
        key: keySecureStorageKey,
        value: _secretKey,
      );
    } else {
      _secretKey = secretKey;
    }

    _database ??= await openDatabase(
      path.join(await getDatabasesPath(), 'timeline.sqlite'),
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''CREATE TABLE settings (
            id INTEGER PRIMARY KEY,
            key TEXT, value TEXT
          )''');
        await db.execute('''CREATE TABLE hosts (
            id INTEGER PRIMARY KEY,
            host TEXT,
            name TEXT,
            username TEXT,
            password TEXT
          )''');
        await db.execute('''CREATE TABLE timelines (
            id INTEGER PRIMARY KEY,
            term_id INTEGER,
            name TEXT,
            description TEXT,
            host_id INT,
            active INT,
            count INT,
            color TEXT,
            FOREIGN KEY(host_id) REFERENCES hosts(id)
          )''');
        await db.execute('''CREATE TABLE items (
            id INTEGER PRIMARY KEY,
            timeline_id INTEGER,
            year INTEGER,
            year_end INTEGER,
            year_name TEXT,
            year_end_name TEXT,
            intro TEXT,
            title TEXT,
            image TEXT,
            links TEXT,
            image_source TEXT,
            image_info TEXT,
            post_id INTEGER,
            has_content INTEGER,
            FOREIGN KEY(timeline_id) REFERENCES timelines(id)
          )''');
      },
    );

    await _initImageCache();
  }

  static String getImageCachePath() {
    return _imageCachePath;
  }

  static Future _initImageCache() async {
    final cacheDir = await path_provider.getApplicationCacheDirectory();
    final dir = Directory('${cacheDir.path}/image-cache');
    if (!await dir.exists()) {
      await dir.create();
    }
    _imageCachePath = dir.path;
  }

  static Future clearImageCache() async {
    final dir = Directory(_imageCachePath);
    await dir.delete(recursive: true);
    await dir.create(recursive: true);
  }

  static Future<String> decrypt(String value) async {
    return await _myCrypt.decrypt(value, _secretKey);
  }

  // Store timeline items from api response into database
  static Future putTimelineItems(
    List items,
    Map<int, int> timelineTermId2IdMap,
  ) async {
    await _database!.transaction((txn) async {
      final batch = txn.batch();
      for (Map<String, Object?> item in items) {
        final meta = item['meta'] as Map<String, Object?>;
        final timelineList = item['mve_timeline'] as List;
        final newItem = {
          'post_id': item['id'],
          'title': item['title_raw'],
          'has_content': (meta['mve_timeline_content'] as bool) ? 1 : 0,
          'timeline_id': timelineTermId2IdMap[timelineList[0]],
          'year': meta['mve_timeline_year'],
          'year_name': meta['mve_timeline_year_name'],
          'year_end_name': meta['mve_timeline_year_end_name'],
          'year_end': meta['mve_timeline_year_end'].toString().isNotEmpty
              ? meta['mve_timeline_year_end']
              : null,
          'intro': meta['mve_timeline_intro'],
          'image': meta['mve_timeline_image_src'],
          'links': meta['mve_timeline_links'],
          'image_source': meta['mve_timeline_image_source'],
          'image_info': meta['mve_timeline_image_info'],
        };
        txn.insert('items', newItem);
      }
      await batch.commit(noResult: true);
    });
  }

  static Future<Settings> getSettings() async {
    final rows = await _database!.query('settings');
    LoadImages loadImages = LoadImages.never;
    bool condensed = false;
    int? imageWidth;
    int? yearWidth;
    bool cachedImages = false;
    bool displayTimelineChart = false;
    MyThemeModes themeMode = MyThemeModes.system;
    for (var row in rows) {
      switch (row['key']) {
        case keySettingsLoadImages:
          if (row['value'] != null && row['value'].toString().isNotEmpty) {
            loadImages = LoadImages.values.firstWhereOrNull(
              (element) => element.value == row['value'],
            )!;
          }
          break;
        case keySettingsCondensed:
          condensed = row['value'].toString() == '1';
          break;
        case keySettingsImageWidth:
          imageWidth = int.tryParse(row['value'].toString());
          break;
        case keySettingsYearWidth:
          yearWidth = int.tryParse(row['value'].toString());
          break;
        case keySettingsThemeMode:
          if (row['value'] != null && row['value'].toString().isNotEmpty) {
            themeMode = MyThemeModes.values.byName(row['value'].toString());
          }
          break;
        case keySettingsCachedImages:
          cachedImages = row['value'].toString() == '1';
          break;
        case keySettingsDisplayTimelineChart:
          displayTimelineChart = row['value'].toString() == '1';
          break;
      }
    }
    return Settings(
      loadImages: loadImages,
      displayTimelineChart: displayTimelineChart,
      yearWidth: yearWidth,
      cachedImages: cachedImages,
      condensed: condensed,
      imageWidth: imageWidth,
      themeMode: themeMode,
    );
  }

  static Future putSettings(Settings settings) async {
    await _database!.transaction((txn) async {
      final batch = txn.batch();
      batch.delete('settings');
      batch.insert('settings', {
        'key': keySettingsLoadImages,
        'value': settings.loadImages.value,
      });
      batch.insert('settings', {
        'key': keySettingsCondensed,
        'value': settings.condensed ? '1' : '0',
      });
      batch.insert('settings', {
        'key': keySettingsDisplayTimelineChart,
        'value': settings.displayTimelineChart ? '1' : '0',
      });
      batch.insert('settings', {
        'key': keySettingsCachedImages,
        'value': settings.cachedImages ? '1' : '0',
      });
      batch.insert('settings', {
        'key': keySettingsImageWidth,
        'value': settings.imageWidth,
      });
      batch.insert('settings', {
        'key': keySettingsYearWidth,
        'value': settings.yearWidth,
      });
      batch.insert('settings', {
        'key': keySettingsThemeMode,
        'value': settings.themeMode.value,
      });
      await batch.commit(noResult: true);
    });
  }

  static Future updateTimelineColor(int timelineId, String? color) async {
    return _database!.update(
      'timelines',
      {'color': color},
      where: 'id = ?',
      whereArgs: [timelineId],
    );
  }

  static Future putActiveTimelineIds(List<int> timelineIds) async {
    await _database!.transaction((txn) async {
      await txn.update('timelines', {'active': 0});
      if (timelineIds.isNotEmpty) {
        await txn.update(
          'timelines',
          {'active': 1},
          where: 'id in (${_paramQuestions(timelineIds)})',
          whereArgs: timelineIds,
        );
      }
    });
  }

  static Future<List<TimelineHost>> getTimelineHosts() async {
    final rows = await _database!.query('hosts', orderBy: 'host ASC');
    return rows.map((e) => TimelineHost.fromMap(e)).toList();
  }

  static Future updateTimelineHost(
    int id,
    String? username,
    String? plainPassword,
  ) async {
    final encryptedPassword = plainPassword != null
        ? (await _myCrypt.encrypt(plainPassword, _secretKey))
        : null;
    await _database!.update(
      'hosts',
      {'username': username, 'password': encryptedPassword},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<TimelineHost> putTimelineHost(
    String host,
    String name,
    String? username,
    String? plainPassword,
  ) async {
    final encryptedPassword = plainPassword != null
        ? (await _myCrypt.encrypt(plainPassword, _secretKey))
        : null;
    final id = await _database!.insert('hosts', {
      'host': host,
      'name': name,
      'username': username,
      'password': encryptedPassword,
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
    List<Map<String, dynamic>> response,
    int timelineHostId,
  ) async {
    await _database!.transaction((txn) async {
      final batch = txn.batch();
      txn.delete(
        'timelines',
        where: 'host_id = ?',
        whereArgs: [timelineHostId],
      );
      for (final timeline in response) {
        txn.insert('timelines', {
          //'term_id': timeline['term_taxonomy_id'], // from custom API
          'term_id': timeline['id'], // from std API
          'name': timeline['name'],
          'description': timeline['description'],
          'host_id': timelineHostId,
          'count': timeline['count'],
          'active': 0,
          // Note: no 'color' because we set this only in the app.
        });
      }
      await batch.commit(noResult: true);
    });
  }

  static Future removeTimelineHosts(
    List<int> hostIds, {
    bool removeHosts = true,
  }) async {
    final timelines = await getTimelines(hostIds: hostIds);
    await _database!.transaction((txn) async {
      await removeTimelineItems(timelines.map((e) => e.id).toList(), txn: txn);
      await txn.delete(
        'timelines',
        where: 'host_id IN (${_paramQuestions(hostIds)})',
        whereArgs: hostIds,
      );
      if (removeHosts) {
        await txn.delete(
          'hosts',
          where: 'id IN (${_paramQuestions(hostIds)})',
          whereArgs: hostIds,
        );
      }
    });
  }

  static Future<YearAndTimelineItems> getTimelineItems(
    List<int> timelineIds,
  ) async {
    final rows = await _database!.query(
      'items',
      where: 'timeline_id IN (${_paramQuestions(timelineIds)})',
      whereArgs: timelineIds,
      orderBy: 'year ASC',
    );
    final List<TimelineAbstractItem> items = [];
    final Map<int, int> years = {}; // year => index
    var index = 0;
    for (final row in rows) {
      final item = TimelineItem.fromDbMap(row);
      if (!years.containsKey(item.year)) {
        years[item.year] = index;
        items.add(TimelineYearItem(year: item.year, yearName: item.yearName));
        index += 1;
      }
      items.add(item);
      index += 1;
    }
    return YearAndTimelineItems(timelineItems: items, yearIndexes: years);
  }

  static Future removeTimelineItems(
    List<int> timelineIds, {
    Transaction? txn,
  }) async {
    await (txn ?? _database!).delete(
      'items',
      where: 'timeline_id IN (${_paramQuestions(timelineIds)})',
      whereArgs: timelineIds,
    );
  }
}

class YearAndTimelineItems extends Equatable {
  final List<TimelineAbstractItem> timelineItems;
  final Map<int, int> yearIndexes;

  const YearAndTimelineItems({
    required this.timelineItems,
    required this.yearIndexes,
  });
  @override
  List<Object?> get props => [timelineItems, yearIndexes];
}
