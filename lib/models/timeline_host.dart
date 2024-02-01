import 'package:equatable/equatable.dart';

class TimelineHost extends Equatable {
  final int id; // Generated on the client by database
  final String host;
  final String name;
  final String? username;
  final String?
      password; // Always encrypted, we only decrypt/encrypt in the store layer.

  const TimelineHost(
      {required this.id,
      required this.host,
      required this.name,
      this.password,
      this.username});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'host': host,
      'name': name,
      'username': username,
      'password': password
    };
  }

  bool isLoggedIn() {
    return username != null &&
        username!.isNotEmpty &&
        password != null &&
        password!.isNotEmpty;
  }

  // Map database row to model
  TimelineHost.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        name = map['name'],
        host = map['host'],
        username = map['username'],
        password = map['password'];

  @override
  List<Object?> get props => [host, id, name, username, password];
}
