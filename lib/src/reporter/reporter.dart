import 'dart:async';

/// Interface for receiving status updates and information from the
/// [RestClient].
abstract class Reporter {
  /// Called when the [RestClient] encounters an failed response or exception.
  /// All times are UTC Millis.
  Future<void> failure({
    required int endTime,
    required String exception,
    required String method,
    required String requestId,
    required StackTrace stack,
    required int startTime,
    required String url,
  });

  /// Called by the [RestClient] just before making the network call.  The given
  /// [requestId] will be consistent for subsequent calls and can be used to
  /// tie updated statuses to this request.
  Future<void> request({
    required dynamic body,
    required Map<String, String> headers,
    required String method,
    required String requestId,
    required String url,
  });

  /// Called by the [RestClient] just after receiving the response from the
  /// remote server.
  Future<void> response({
    required dynamic body,
    required Map<String, String>? headers,
    required String requestId,
    required int statusCode,
  });

  /// Called by the [RestClient] when a successful response has been processed.
  /// All times are UTC Millis.
  Future<void> success({
    required int bytesReceived,
    required int bytesSent,
    required int endTime,
    required String method,
    required String requestId,
    required int startTime,
    required int statusCode,
    required String url,
  });
}
