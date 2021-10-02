import 'package:logging/logging.dart';
import 'package:rest_client/rest_client.dart';

/// Reporter that will write API events to either the provided [Logger], or a
/// global default one.
class LoggerReporter implements Reporter {
  LoggerReporter({
    Level? level,
    Logger? logger,
  })  : _level = level ?? Level.FINER,
        _logger = logger ?? Logger('LoggingReporter');

  final Level _level;
  final Logger _logger;

  @override
  Future<void> failure({
    required int endTime,
    required String exception,
    required String method,
    required String requestId,
    required StackTrace stack,
    required int startTime,
    required String url,
  }) async =>
      _logger.log(_level, '''
--------------------------------------------------------------------------------
API FAILURE:
  * Request: $method $url
  * Request ID: $requestId
  * Error: $exception
  * Stack: $stack
--------------------------------------------------------------------------------
''');

  @override
  Future<void> request({
    required body,
    required Map<String, String> headers,
    required String method,
    required String requestId,
    required String url,
  }) async =>
      _logger.log(_level, '''
--------------------------------------------------------------------------------
API REQUEST:
  * Request: $method $url
  * Request ID: $requestId
  * Headers: $headers
  * Body: $body
--------------------------------------------------------------------------------
''');

  @override
  Future<void> response({
    required dynamic body,
    required Map<String, String>? headers,
    required String requestId,
    required int statusCode,
  }) async =>
      _logger.log(_level, '''
--------------------------------------------------------------------------------
API RESPONSE:
  * Status: $statusCode
  * Request ID: $requestId
  * Headers: $headers
  * Body: $body
--------------------------------------------------------------------------------
''');

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
  }) async =>
      _logger.log(_level, '''
--------------------------------------------------------------------------------
API SUCCESS:
  * Request: $method $url
  * Request ID: $requestId
  * Status: $statusCode
  * Bytes: $bytesSent : $bytesReceived
  * Duration: ${(endTime - startTime) / 1000}ms
--------------------------------------------------------------------------------
''');
}
