import 'package:equatable/equatable.dart';
import 'package:timeline/utils.dart';

class Timeline extends Equatable {
  final int id; // auto generated on client
  final int termId; // from backend
  final int hostId;
  final String name;
  final String description;
  final int active;
  final int? yearMin;
  final int? yearMax;
  final int count;
  final String? color; // Set in app only, hex string

  const Timeline({
    required this.id,
    required this.termId,
    required this.hostId,
    required this.name,
    required this.active,
    required this.description,
    this.color,
    this.count = 0,
    this.yearMax,
    this.yearMin,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    hostId,
    termId,
    active,
    yearMax,
    yearMax,
    count,
    color,
  ];

  Timeline copyWith({String? color, bool removeColor = false}) {
    return Timeline(
      id: id,
      termId: termId,
      hostId: hostId,
      name: name,
      active: active,
      description: description,
      color: removeColor ? null : (color ?? this.color),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'active': active,
      'term_id': termId,
      'host_id': hostId,
      'name': name,
      'description': description,
      'year_min': yearMin,
      'year_max': yearMax,
      'count': count,
      'color': color,
    };
  }

  String yearMinMax() {
    if (yearMax != null) {
      return '$yearMin / $yearMax';
    } else {
      return yearMin.toString();
    }
  }

  bool isActive() => active == 1;

  Timeline.fromMap(Map<String, dynamic> map, {int? hostId, int? active})
    : id = map['id'],
      termId = map['term_id'],
      count = map['count'],
      active = active ?? map['active'],
      name = map['name'],
      color = map['color'],
      hostId =
          hostId ??
          map['host_id'], // When we select from database, myHostId can be null, but when we fetch from API, then we need myHostId.
      description = map['description'],
      yearMin = map['year_min'],
      yearMax = map['year_max'];
}
