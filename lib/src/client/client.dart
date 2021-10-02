import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:rest_client/rest_client.dart';
import 'package:uuid/uuid.dart';

/* 
 * Mechanism to selectively pull in the correct code based on whether we are 
 * running in a Flutter based application or a Dart Web based application.
 * 
 * Dart Web uses a BrowserClient and does not support Isolates for performing 
 * the JSON parsing.  Flutter utilizes the IOClient and does support Isolates
 * to parse the JSON on a background thread to avoid jank during large REST
 * responses.
 */
// ignore: uri_does_not_exist
import 'clients/stub_client.dart'
    // ignore: uri_does_not_exist
    if (dart.library.html) 'clients/browser_client.dart'
    // ignore: uri_does_not_exist
    if (dart.library.io) 'clients/io_client.dart';

const _kDefaultTimeout = Duration(seconds: 60);

@immutable
class Client {
  /// Constructs the client with instance level defaults for the [reporter],
  /// [proxy], and [timeout].  All of which are optional.
  ///
  /// If the [timeout] is set, it must be at least 1 second.  Otherwise it will
  /// default to 60 seconds.
  ///
  /// Because this is immutable, users of this have the option to create a
  /// single application wide instance to reuse for all calls, or to create
  /// instances on a more ad hoc basiss.  Both mechanisms are supported.
  Client({
    Reporter? reporter,
    Proxy? proxy,
    this.timeout = _kDefaultTimeout,
  })  : assert(timeout.inMilliseconds >= 1000),
        _reporter = reporter,
        _proxy = proxy;

  static final Logger _logger = Logger('Client');

  /// Sets the global [Proxy] for all [Client] instances to use as the fallback
  /// default.
  static Proxy? proxy;

  /// Sets the global [Reporter] for all [Client] instances to use as the
  /// fallback default.
  static Reporter? reporter;

  final Proxy? _proxy;
  final Reporter? _reporter;
  final Duration timeout;

  /// Executes the given [request].  This accepts an optional [authorizer] to
  /// provide authorization to the final end point.
  ///
  /// This accepts an optional [emitter] that can be used to post the response
  /// to a listener.  If the [emitter] is provided, closing the [emitter] will
  /// result in the call being cancelled and any retries will be stopped.
  ///
  /// The [reporter] argument will override the instance and global level
  /// [reporter] objects.
  ///
  /// If [retryCount] is greater than zero then the [retryDelay] must also be
  /// set.  The backoff strategy for subsequent retries will be determined by
  /// the [retryDelayStrategy].  If not set, this will default to
  /// [DelayStrategies.linear].
  Future<Response> execute({
    Authorizer? authorizer,
    StreamController<Response>? emitter,
    required Request request,
    Reporter? reporter,
    int retryCount = 0,
    Duration retryDelay = const Duration(seconds: 1),
    DelayStrategy? retryDelayStrategy,
    Duration? timeout,
  }) async {
    assert(timeout == null || timeout.inMilliseconds >= 1000);
    assert(retryCount >= 0);
    assert(retryCount == 0 || (retryDelay.inMilliseconds >= 1000));

    var attempts = 0;
    var initialRetryDelay = retryDelay;
    var fatalError = false;
    while (fatalError != true && (attempts == 0 || attempts <= retryCount)) {
      attempts++;

      var restClient = createHttpClient(proxy: _proxy ?? proxy);

      try {
        reporter = reporter ?? _reporter ?? Client.reporter;

        var requestId = Uuid().v4();
        var startTime = DateTime.now().millisecondsSinceEpoch;
        var headers = request.prepareHeaders();
        var method = request.method.toString();

        var httpRequest = http.Request(
          method,
          Uri.parse(request.url),
        );
        if (request.body?.isNotEmpty == true) {
          httpRequest.body = request.body ?? '';
        }
        httpRequest.headers.addAll(headers);
        authorizer?.secure(httpRequest);

        String? body;
        int? statusCode;
        Map<String, String>? responseHeaders;

        dynamic exception;
        await reporter?.request(
          body: request.body,
          headers: headers,
          method: method,
          requestId: requestId,
          url: request.url,
        );

        try {
          var response = await restClient.send(httpRequest).timeout(
                timeout ?? this.timeout,
              );
          body = await response.stream.transform(utf8.decoder).join();
          responseHeaders = response.headers;
          statusCode = response.statusCode;

          await reporter?.response(
            body: body,
            headers: response.headers,
            requestId: requestId,
            statusCode: response.statusCode,
          );
        } catch (e, stack) {
          exception = e;

          await reporter?.failure(
            endTime: DateTime.now().millisecondsSinceEpoch,
            exception: e.toString(),
            method: method,
            requestId: requestId,
            stack: stack,
            startTime: startTime,
            url: request.url,
          );
        }

        dynamic responseBody;
        if (body?.isNotEmpty == true) {
          responseBody = await processJson(body!);
        }

        var response = Response(
          body: responseBody,
          headers: responseHeaders,
          statusCode: statusCode,
        );

        // If the response is fatal (as in, a retry is exceptionally unlikely to
        // succeed), then set the flag to abort any regry logic.
        fatalError = _isFatal(response.statusCode);

        if (exception == null) {
          await reporter?.success(
            bytesReceived: body?.codeUnits.length ?? 0,
            bytesSent: request.body?.codeUnits.length ?? 0,
            endTime: DateTime.now().millisecondsSinceEpoch,
            method: method,
            requestId: requestId,
            startTime: startTime,
            statusCode: response.statusCode!,
            url: request.url,
          );

          if (response.statusCode == null ||
              response.statusCode! < 200 ||
              response.statusCode! >= 400) {
            throw RestException(
              message: exception != null
                  ? 'Error from server: ${exception}'
                  : 'Error code received from server: ${response.statusCode}',
              response: response,
            );
          }
        } else {
          throw RestException(
            message: exception != null
                ? 'Error from server: ${exception}'
                : 'Error code received from server: ${response.statusCode}',
            response: response,
          );
        }
        return response;
      } catch (e) {
        _logger.severe('Error: ${request.url}');
        if (retryCount < attempts) {
          rethrow;
        }
        _logger.severe(
            'Attempt failed: ($attempts of $retryCount) waiting ${retryDelay.inMilliseconds}ms');

        if (emitter?.isClosed == true) {
          _logger.info('Emitter is closed; cancelling');
          rethrow;
        }
        await Future.delayed(retryDelay);
        if (emitter?.isClosed == true) {
          _logger.info('Emitter is closed; cancelling');
          rethrow;
        }

        var strategy = retryDelayStrategy ?? DelayStrategies.linear;
        retryDelay = strategy(
          current: retryDelay,
          initial: initialRetryDelay,
        );
      } finally {
        restClient.close();
      }
    }

    throw 'UNKNOWN ERROR';
  }

  /// Returns if the given status code should be considered fatal.  A fatal
  /// error is one where an as-is retry is virtually guaranteed to fail.
  bool _isFatal(int? status) =>
      status == null ||
      [
        400, // Bad Request
        401, // Unauthorized
        402, // Payment Required
        403, // Forbidden
        404, // Not Found
        405, // Method Not Allowed,
        413, // Request Entity Too Large
        414, // Request URI Too Long,
        415, // Unsupported Media Type
      ].contains(status);
}
