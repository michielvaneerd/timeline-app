import 'package:equatable/equatable.dart';

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

  const Timeline(
      {required this.id,
      required this.termId,
      required this.hostId,
      required this.name,
      required this.active,
      required this.description,
      this.count = 0,
      this.yearMax,
      this.yearMin});

  @override
  List<Object?> get props =>
      [id, name, description, hostId, termId, active, yearMax, yearMax, count];

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
      'count': count
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
        hostId = hostId ??
            map['host_id'], // When we select from database, myHostId can be null, but when we fetch from API, then we need myHostId.
        description = map['description'],
        yearMin = map['year_min'],
        yearMax = map['year_max'];
}
