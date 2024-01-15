import 'package:equatable/equatable.dart';

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

  final String title;

  const TimelineItem(this.image, this.intro, this.title,
      {required this.id, required this.timelineId, required super.year});

  @override
  List<Object?> get props => [id, image, intro, year, title, timelineId];

  // Can be called when we get response from server (then we don't have a timelineId)
  // or when getting from DB (in this case we HAVE a timelineId)
  TimelineItem.fromMap(Map<String, dynamic> map, {int? timelineId})
      : id = int.parse(map['id'].toString()),
        timelineId = timelineId ?? map['timeline_id'],
        image = map['image'],
        intro = map['intro'],
        title = map['title'],
        super(year: int.parse(map['year'].toString()));
}
