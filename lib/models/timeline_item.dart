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
  final int id;
  final int timelineId;
  final String? image;
  final String intro;
  final List<TimelineItemLink> links;
  final String title;
  final String? imageSource;
  final String? imageInfo;
  final int? yearEnd;

  const TimelineItem(this.image, this.intro, this.title,
      {required this.id,
      required this.timelineId,
      required super.year,
      this.yearEnd,
      this.imageSource,
      this.imageInfo,
      required this.links});

  @override
  List<Object?> get props =>
      [id, image, intro, year, title, timelineId, yearEnd];

  // Can be called when we get response from server (then we don't have a timelineId)
  // or when getting from DB (in this case we HAVE a timelineId)
  TimelineItem.fromMap(Map<String, dynamic> map, {int? timelineId})
      : id = int.parse(map['id'].toString()),
        timelineId = timelineId ?? map['timeline_id'],
        imageSource = map['image_source'],
        imageInfo = map['image_info'],
        yearEnd = map['year_end'] != null && map['year_end'] != ''
            ? int.parse(map['year_end'].toString())
            : null,
        links = map.containsKey('links') &&
                map['links'] != null &&
                map['links'].toString().isNotEmpty
            ? (convert.jsonDecode(map['links']) as List).map((e) {
                return TimelineItemLink.fromMap((e as Map<String, dynamic>)
                    .map<String, String>(
                        (key, value) => MapEntry(key, value.toString())));
              }).toList()
            : [],
        image = map['image'],
        intro = map['intro'],
        title = map['title'],
        super(year: int.parse(map['year'].toString()));
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
