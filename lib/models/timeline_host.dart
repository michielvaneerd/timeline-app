import 'package:equatable/equatable.dart';

class TimelineHost extends Equatable {
  final int id; // Generated on the client by database
  final String host;
  final String name;

  const TimelineHost(
      {required this.id, required this.host, required this.name});

  Map<String, dynamic> toMap() {
    return {'id': id, 'host': host, 'name': name};
  }

  TimelineHost.fromMap(Map<String, dynamic> map)
      : id = map[
            'id'], // Only used to map database result to model instance, so id never will be null.
        name = map['name'],
        host = map['host'];

  @override
  List<Object?> get props => [host, id, name];
}
