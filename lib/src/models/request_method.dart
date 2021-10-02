class RequestMethod {
  const RequestMethod._(this._code);

  static const delete = RequestMethod._('DELETE');
  static const get = RequestMethod._('GET');
  static const patch = RequestMethod._('PATCH');
  static const post = RequestMethod._('POST');
  static const put = RequestMethod._('PUT');

  final String _code;

  @override
  String toString() => _code;
}
