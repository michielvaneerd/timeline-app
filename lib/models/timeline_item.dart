import 'package:equatable/equatable.dart';
import 'dart:convert' as convert;

abstract class TimelineAbstractItem extends Equatable {
  final int year;
  const TimelineAbstractItem({required this.year});
  @override
  List<Object?> get props => [year];
}

class TimelineYearItem extends TimelineAbstractItem {
  const TimelineYearItem({required super.year});
}

class TimelineItem extends TimelineAbstractItem {
  final int? id;
  final int? timelineId;
  final String? image;
  final String intro;
  final List<TimelineItemLink> links;
  final String title;
  final String? imageSource;
  final String? imageInfo;
  final int? yearEnd;
  final int postId;
  final bool hasContent;
  final String? modified; // Only for draft items

  const TimelineItem(
      {this.id,
      this.image,
      required this.intro,
      required this.title,
      required this.timelineId,
      required super.year,
      required this.postId,
      required this.hasContent,
      this.yearEnd,
      this.imageSource,
      this.imageInfo,
      this.modified,
      required this.links});

  @override
  List<Object?> get props => [
        id,
        image,
        intro,
        year,
        title,
        timelineId,
        yearEnd,
        postId,
        modified,
        hasContent
      ];

  Map<String, dynamic> toDraftMap(int timelineExternalId) {
    return {
      'title': title,
      'meta': {
        'mve_timeline_year': year.toString(),
        'mve_timeline_year_end': yearEnd?.toString(),
        'mve_timeline_intro': intro
      },
      'mve_timeline': [timelineExternalId]
    };
  }

  TimelineItem copyWith(
      {String? title,
      int? timelineId,
      int? year,
      int? yearEnd,
      bool useYearEndParam = false}) {
    return TimelineItem(
        hasContent: hasContent,
        image: image,
        intro: intro,
        title: title ?? this.title,
        timelineId: timelineId ?? this.timelineId,
        year: year ?? this.year,
        yearEnd: useYearEndParam ? yearEnd : (yearEnd ?? this.yearEnd),
        postId: postId,
        links: links);
  }

  static List<TimelineItemLink> _getLinks(String? links) {
    if (links == null || links.isEmpty) {
      return [];
    }
    return convert.jsonDecode(links).map((e) {
      return TimelineItemLink.fromMap((e as Map<String, dynamic>)
          .map<String, String>(
              (key, value) => MapEntry(key, value.toString())));
    }).toList();
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
        links = _getLinks(map['links']),
        image = map['image'],
        intro = map['intro'],
        title = map['title'] ?? '',
        super(year: map['year']);

  // Used when mapping draft items.
  static TimelineItem fromApiMap(Map<String, dynamic> map, int? timelineId) {
    final meta = map['meta'] as Map;
    return TimelineItem(
        intro: meta['mve_timeline_intro'],
        title: map['title_raw'],
        hasContent: meta['mve_timeline_content'],
        timelineId: timelineId,
        modified: map['modified'],
        image: meta['mve_timeline_image_src'],
        imageInfo: meta['mve_timeline_image_info'],
        imageSource: meta['mve_timeline_image_source'],
        year: int.tryParse(meta['mve_timeline_year']) ?? 0,
        yearEnd: meta['mve_timeline_year_end'].toString().isNotEmpty
            ? int.parse(meta['mve_timeline_year_end'])
            : null,
        postId: map['id'],
        links: _getLinks(meta['mve_timeline_links']));
  }
}

class TimelineItemLink extends Equatable {
  final String name;
  final String url;

  const TimelineItemLink({required this.name, required this.url});
  @override
  List<Object?> get props => [name, url];

  TimelineItemLink.fromMap(Map<String, String> map)
      : name = map['name']!,
        url = map['url']!;
}
