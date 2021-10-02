import 'package:rest_client/rest_client.dart';
import 'package:test/test.dart';

void main() {
  test('success', () async {
    var request = Request(
      method: RequestMethod.get,
      url: 'https://archive.org/metadata/principleofrelat00eins',
    );

    var client = Client();
    var response = await client.execute(request: request);

    expect(true, response.body != null);
  });
}
