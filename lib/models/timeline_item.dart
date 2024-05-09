import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'dart:convert' as convert;
import 'package:intl/intl.dart' as intl;

abstract class TimelineAbstractItem extends Equatable {
  final int year;
  final String? yearName;
  const TimelineAbstractItem({required this.year, this.yearName});
  String getYear() {
    return yearName != null && yearName!.isNotEmpty
        ? yearName!
        : year.toString();
  }

  @override
  List<Object?> get props => [year, yearName];
}

class TimelineYearItem extends TimelineAbstractItem {
  const TimelineYearItem({required super.year, super.yearName});
}

class TimelineItem extends TimelineAbstractItem {
  final int? id;
  final int? timelineId;
  final Map<TimelineItemImageSizes, TimelineItemImage>
      image; // for example: large: {}, medium: {}
  final String intro;
  final List<TimelineItemLink> links;
  final String title;
  final String? imageSource;
  final String? imageInfo;
  final int? yearEnd;
  final String? yearEndName;
  final int postId;
  final bool hasContent;
  final DateTime? modified; // Only for draft items

  static final dateFormat = intl.DateFormat('y-MM-ddTHH:mm:ss');

  const TimelineItem(
      {this.id,
      required this.image,
      required this.intro,
      required this.title,
      required this.timelineId,
      required super.year,
      super.yearName,
      this.yearEndName,
      required this.postId,
      required this.hasContent,
      this.yearEnd,
      this.imageSource,
      this.imageInfo,
      this.modified,
      required this.links});

  String? getYearEnd() {
    return yearEndName != null && yearEndName!.isNotEmpty
        ? yearEndName!
        : yearEnd?.toString();
  }

  @override
  List<Object?> get props => [
        id,
        image,
        intro,
        year,
        yearName,
        title,
        timelineId,
        yearEnd,
        yearEndName,
        postId,
        modified,
        hasContent
      ];

  String years() {
    if (getYearEnd() == null) {
      return getYear();
    }
    return '${getYear()} / ${getYearEnd()}';
  }

  Map<String, dynamic> toDraftMap(int timelineExternalId) {
    return {
      'title': title,
      'meta': {
        'mve_timeline_year': year.toString(),
        'mve_timeline_year_end': yearEnd?.toString(),
        'mve_timeline_year_name': yearName?.toString(),
        'mve_timeline_year_end_name': yearEndName?.toString(),
        'mve_timeline_intro': intro,
        'mve_timeline_links': convert.json.encode(links)
      },
      'mve_timeline': [timelineExternalId]
    };
  }

  TimelineItem copyWith(
      {String? title,
      int? timelineId,
      int? year,
      String? yearName,
      bool removeYearName = false,
      String? yearEndName,
      bool removeYearEndName = false,
      int? yearEnd,
      bool removeYearEnd = false}) {
    return TimelineItem(
        hasContent: hasContent,
        image: image,
        intro: intro,
        title: title ?? this.title,
        timelineId: timelineId ?? this.timelineId,
        year: year ?? this.year,
        yearName: removeYearName ? null : (yearName ?? this.yearName),
        yearEndName:
            removeYearEndName ? null : (yearEndName ?? this.yearEndName),
        yearEnd: removeYearEnd ? null : (yearEnd ?? this.yearEnd),
        postId: postId,
        links: links);
  }

  static List<TimelineItemLink> _getLinks(String? links) {
    if (links == null || links.isEmpty) {
      return [];
    }
    final items = convert.jsonDecode(links) as List;
    final newLinks = items
        .map((e) => TimelineItemLink.fromJson(e as Map<String, dynamic>))
        .toList();
    return newLinks;
    //final items = convert.jsonDecode(links).map((e) {
    //  return TimelineItemLink.fromJson((e as Map<String, dynamic>));
    // return TimelineItemLink.fromJson((e as Map<String, dynamic>)
    //     .map<String, String>(
    //         (key, value) => MapEntry(key, value.toString())));
    //});
  }

  static Map<TimelineItemImageSizes, TimelineItemImage> _getImage(
      String? image) {
    if (image == null || image.isEmpty) {
      return {};
    }
    return (convert.jsonDecode(image) as Map).map((key, value) => MapEntry(
        TimelineItemImageSizesExtension.byNameOrUnknown(key),
        TimelineItemImage.fromMap(value as Map<String, dynamic>)));
  }

  // Only when mapping db rows
  TimelineItem.fromDbMap(Map<String, dynamic> map)
      : id = map['id'],
        postId = map['post_id'],
        timelineId = map['timeline_id'],
        imageSource = map['image_source'],
        hasContent = map['has_content'] == 1,
        imageInfo = map['image_info'],
        modified = null, // Only for draft items that we get from the server
        yearEnd = map['year_end'],
        yearEndName = map['year_end_name'],
        links = _getLinks(map['links']),
        image = _getImage(map['image']),
        intro = map['intro'],
        title = map['title'] ?? '',
        super(year: map['year'], yearName: map['year_name']);

  // Used when mapping draft items.
  static TimelineItem fromApiMap(Map<String, dynamic> map, int? timelineId) {
    final meta = map['meta'] as Map;
    return TimelineItem(
        intro: meta['mve_timeline_intro'],
        title: map['title_raw'],
        hasContent: meta['mve_timeline_content'],
        timelineId: timelineId,
        modified: dateFormat.parse(map['modified']),
        image: _getImage(meta['mve_timeline_image_src']),
        imageInfo: meta['mve_timeline_image_info'],
        imageSource: meta['mve_timeline_image_source'],
        year: int.tryParse(meta['mve_timeline_year']) ?? 0,
        yearEnd: meta['mve_timeline_year_end'].toString().isNotEmpty
            ? int.parse(meta['mve_timeline_year_end'])
            : null,
        yearName: meta['mve_timeline_year_name'],
        yearEndName: meta['mve_timeline_year_end_name'],
        postId: map['id'],
        links: _getLinks(meta['mve_timeline_links']));
  }

  TimelineItemImage? getImage(TimelineItemImageSizes key1,
      {TimelineItemImageSizes? key2, TimelineItemImageSizes? key3}) {
    if (image.containsKey(key1)) {
      return image[key1];
    } else if (key2 != null && image.containsKey(key2)) {
      return image[key2];
    } else if (key3 != null && image.containsKey(key3)) {
      return image[key3];
    } else {
      return null;
    }
  }
}

class TimelineItemLink extends Equatable {
  final String name;
  final String url;

  const TimelineItemLink({required this.name, required this.url});
  @override
  List<Object?> get props => [name, url];

  Map<String, dynamic> toJson() {
    return {'name': name, 'url': url};
  }

  TimelineItemLink.fromJson(Map<String, dynamic> map)
      : name = map['name'] as String,
        url = map['url'] as String;
}

// Used when editing so we can set the deleted flag.
class DraftTimelineItemLink extends TimelineItemLink {
  final bool deleted;
  const DraftTimelineItemLink(
      {required super.name, required super.url, required this.deleted});
}

enum TimelineItemImageSizes {
  thumbnail('Thumbnail', 'thumbnail'),
  medium('Medium', 'medium'),
  large('Large', 'large'),
  full('Full', 'full'),
  unknown('Unknown', 'unknown');

  const TimelineItemImageSizes(this.label, this.value);
  final String label;
  final String value;
}

extension TimelineItemImageSizesExtension on TimelineItemImageSizes {
  static TimelineItemImageSizes byNameOrUnknown(String name) {
    return TimelineItemImageSizes.values
            .firstWhereOrNull((element) => element.name == name) ??
        TimelineItemImageSizes.unknown;
  }
}

class TimelineItemImage extends Equatable {
  final String url;
  final int height;
  final int width;
  final String orientation;

  const TimelineItemImage(
      {required this.url,
      required this.height,
      required this.width,
      required this.orientation});

  @override
  List<Object?> get props => [url, height, width, orientation];

  TimelineItemImage.fromMap(Map<String, dynamic> map)
      : url = map['url'],
        height = map['height'],
        width = map['width'],
        orientation = map['orientation'];
}
