import 'package:meta/meta.dart';

@immutable
class Response {
  Response({
    this.body,
    this.headers,
    this.statusCode,
  });

  final dynamic body;
  final Map<String, String>? headers;
  final int? statusCode;
}
