import 'package:meta/meta.dart';

import 'response.dart';

@immutable
class RestException implements Exception {
  const RestException({
    required this.message,
    required this.response,
  });

  final String message;
  final Response response;

  @override
  String toString() => 'RestException: $message';
}
