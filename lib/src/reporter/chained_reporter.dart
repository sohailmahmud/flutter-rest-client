import 'package:meta/meta.dart';
import 'package:rest_client/rest_client.dart';

/// Reporter that will chain the the reporting calls through a list of child
/// [Reporter].
@immutable
class ChainedReporter implements Reporter {
  ChainedReporter({
    required List<Reporter>? children,
  }) : children = List.unmodifiable(children ?? []);

  final List<Reporter> children;

  @override
  Future<void> failure({
    required int endTime,
    required String exception,
    required String method,
    required String requestId,
    required StackTrace stack,
    required int startTime,
    required String url,
  }) async {
    for (var reporter in children) {
      await reporter.failure(
        endTime: endTime,
        exception: exception,
        method: method,
        requestId: requestId,
        stack: stack,
        startTime: startTime,
        url: url,
      );
    }
  }

  @override
  Future<void> request({
    required dynamic body,
    required Map<String, String> headers,
    required String method,
    required String requestId,
    required String url,
  }) async {
    for (var reporter in children) {
      await reporter.request(
        body: body,
        headers: headers,
        method: method,
        requestId: requestId,
        url: url,
      );
    }
  }

  @override
  Future<void> response({
    required dynamic body,
    required Map<String, String>? headers,
    required String requestId,
    required int statusCode,
  }) async {
    for (var reporter in children) {
      await reporter.response(
        body: body,
        headers: headers,
        requestId: requestId,
        statusCode: statusCode,
      );
    }
  }

  @override
  Future<void> success({
    required int bytesReceived,
    required int bytesSent,
    required int endTime,
    required String method,
    required String requestId,
    required int startTime,
    required int statusCode,
    required String url,
  }) async {
    for (var reporter in children) {
      await reporter.success(
        bytesReceived: bytesReceived,
        bytesSent: bytesSent,
        endTime: endTime,
        method: method,
        requestId: requestId,
        startTime: startTime,
        statusCode: statusCode,
        url: url,
      );
    }
  }
}
