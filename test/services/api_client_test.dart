import 'package:flutter_test/flutter_test.dart';
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
  });
}
