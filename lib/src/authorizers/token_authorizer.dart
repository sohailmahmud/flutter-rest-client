import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:rest_client/rest_client.dart';

/// Authorizor to provide `Bearer` tokents.
@immutable
class TokenAuthorizer extends Authorizer {
  /// Constructs the authorizer with the given token to pass to the back end.
  TokenAuthorizer({
    required this.token,
  });

  final String token;

  /// Attaches the token as a `Bearer` token to the `authorization` header.
  @override
  void secure(http.Request httpRequest) {
    httpRequest.headers['authorization'] = 'Bearer $token';
  }
}
