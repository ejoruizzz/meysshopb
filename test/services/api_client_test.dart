import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:meysshop_front1/services/api_client.dart';

void main() {
  group('_resolveUri', () {
    test('combina correctamente cuando la base no tiene ruta', () {
      final client = ApiClient(baseUrl: 'http://localhost:3001');

      final uri = client.resolveUriForTest(
        '/api/products',
        {'page': 2, 'active': true, 'ignored': null},
      );

      expect(uri.scheme, 'http');
      expect(uri.host, 'localhost');
      expect(uri.port, 3001);
      expect(uri.path, '/api/products');
      expect(uri.queryParameters, {'page': '2', 'active': 'true'});
    });

    test('mantiene el prefijo existente cuando la base ya incluye /api', () {
      final client = ApiClient(baseUrl: 'http://localhost:3001/api');

      final absolute = client.resolveUriForTest('/api/orders', {'limit': 5});
      expect(absolute.path, '/api/orders');
      expect(absolute.queryParameters, {'limit': '5'});

      final relative = client.resolveUriForTest('orders/123');
      expect(relative.toString(), 'http://localhost:3001/api/orders/123');
    });

    test('mantiene solo los parámetros propios de URLs absolutas externas', () {
      final client = ApiClient(
        baseUrl: 'https://api.meysshop.com/base?lang=es&version=1',
      );

      final uri = client.resolveUriForTest(
        'https://cdn.meysshop.com/assets/image.png?size=large&format=webp',
        {'quality': 80, 'ignored': null},
      );

      expect(uri.scheme, 'https');
      expect(uri.host, 'cdn.meysshop.com');
      expect(uri.path, '/assets/image.png');
      expect(
        uri.queryParameters,
        {'size': 'large', 'format': 'webp', 'quality': '80'},
      );
    });
  });

  group('reintentos automáticos', () {
    test('recrea el multipart al reintentar tras refrescar tokens', () async {
      final client = _SequencedClient([
        (request) async {
          expect(request, isA<http.MultipartRequest>());
          return _jsonResponse(401, {'detail': 'unauthorized'});
        },
        (request) async {
          expect(request, isA<http.Request>());
          expect(request.url.path, '/api/auth/refresh');
          return _jsonResponse(
            200,
            {
              'access': 'token-2',
              'refresh': 'refresh-token-2',
            },
          );
        },
        (request) async {
          expect(request, isA<http.MultipartRequest>());
          expect(request.headers['authorization'], 'Bearer token-2');
          return _jsonResponse(200, {'ok': true});
        },
      ]);

      final apiClient = ApiClient(
        baseUrl: 'http://localhost:3001',
        httpClient: client,
      )
        ..updateTokens(accessToken: 'token-1', refreshToken: 'refresh-token');

      final multipart = http.MultipartRequest(
        'POST',
        Uri.parse('http://localhost:3001/upload'),
      )
        ..fields['field'] = 'value'
        ..files.add(
          http.MultipartFile.fromString(
            'file',
            'contenido',
            filename: 'archivo.txt',
          ),
        );

      final response = await apiClient.post('/upload', body: multipart);

      expect(response, {'ok': true});
      expect(client.requestLog.length, 3);
      expect(client.requestLog[0].headers['authorization'], 'Bearer token-1');
      expect(client.requestLog[0], isNot(same(client.requestLog[2])));

      final retryRequest = client.requestLog[2] as http.MultipartRequest;
      expect(retryRequest.headers['authorization'], 'Bearer token-2');
      expect(retryRequest.url.toString(), 'http://localhost:3001/upload');
    });
  });
}

http.StreamedResponse _jsonResponse(int statusCode, Map<String, dynamic> body) {
  final encoded = utf8.encode(jsonEncode(body));
  return http.StreamedResponse(
    Stream<List<int>>.value(encoded),
    statusCode,
    headers: const {'content-type': 'application/json'},
  );
}

class _SequencedClient extends http.BaseClient {
  _SequencedClient(Iterable<Future<http.StreamedResponse> Function(http.BaseRequest)> handlers)
      : _handlers = Queue.of(handlers);

  final Queue<Future<http.StreamedResponse> Function(http.BaseRequest)> _handlers;
  final List<http.BaseRequest> requestLog = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requestLog.add(request);
    await request.finalize().drain<void>();
    if (_handlers.isEmpty) {
      throw StateError('No hay handler configurado para ${request.method} ${request.url}');
    }
    return _handlers.removeFirst()(request);
  }
}
