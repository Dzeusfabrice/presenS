import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LoggedClient extends http.BaseClient {
  final http.Client _inner;

  LoggedClient([http.Client? inner]) : _inner = inner ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final method = request.method;
    final uri = request.url.toString();

    String? requestBody;
    if (request is http.Request) {
      requestBody = request.body;
    }

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('HTTP REQUEST: [$method] $uri');
    if (request.headers.isNotEmpty) {
      print('Request Headers: ${request.headers}');
    }
    if (requestBody != null && requestBody.isNotEmpty) {
      print('Request Body: $requestBody');
    }
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    final streamedResponse = await _inner.send(request);

    // Read response bytes to log body, then recreate a StreamedResponse to return.
    final bytes = await streamedResponse.stream.toBytes();
    final body = bytes.isNotEmpty ? utf8.decode(bytes) : '';

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('HTTP RESPONSE: [${streamedResponse.statusCode}] $uri');
    if (streamedResponse.headers.isNotEmpty) {
      print('Response Headers: ${streamedResponse.headers}');
    }
    if (body.isNotEmpty) {
      print('Response Body: $body');
    }
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    return http.StreamedResponse(
      Stream.fromIterable([bytes]),
      streamedResponse.statusCode,
      contentLength: bytes.length,
      request: streamedResponse.request,
      headers: streamedResponse.headers,
      isRedirect: streamedResponse.isRedirect,
      persistentConnection: streamedResponse.persistentConnection,
      reasonPhrase: streamedResponse.reasonPhrase,
    );
  }
}
