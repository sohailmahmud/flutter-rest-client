import 'package:http/http.dart' as http;

/// Interface for providing authorization for HTTP based API calls.
abstract class Authorizer {
  /// Alters the given request to provide the appropriate authorization to make
  /// the API calls.
  void secure(http.Request httpRequest);
}
