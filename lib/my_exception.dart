import 'package:equatable/equatable.dart';

enum MyExceptionType {
  offline,
  unauthenticated,
  internetConnection,
  duplicateHost,
  notFound,
  unknown,
}

class MyException extends Equatable {
  final MyExceptionType type;

  const MyException({required this.type});
  @override
  List<Object?> get props => [type];
}
