import '../models/product.dart';
import 'api_client.dart';
import 'product_repository.dart';

class ApiProductRepository implements ProductRepository {
  ApiProductRepository(this._client);

  final ApiClient _client;
  static const String _basePath = '/api/productos';

  @override
  Future<List<Product>> fetchProducts({String? search}) async {
    final query = <String, dynamic>{};
    if (search != null && search.trim().isNotEmpty) {
      query['q'] = search.trim();
    }
    final data = await _client.get(
      _basePath,
      queryParameters: query.isEmpty ? null : query,
    );
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(Product.fromJson)
          .toList(growable: false);
    }
    throw const FormatException('Respuesta inesperada al listar productos');
  }

  @override
  Future<Product> createProduct(Product p) async {
    final payload = p.toJson();
    final data = await _client.post(_basePath, body: payload);
    if (data is Map<String, dynamic>) {
      return Product.fromJson(data);
    }
    throw const FormatException('Respuesta inesperada al crear producto');
  }

  @override
  Future<Product> updateProduct(Product p) async {
    final id = p.id;
    if (id == null || id.isEmpty) {
      throw const ArgumentError('El producto debe tener un id para actualizarse');
    }
    final data = await _client.put(
      '$_basePath/${Uri.encodeComponent(id)}',
      body: p.toJson(),
    );
    if (data is Map<String, dynamic>) {
      return Product.fromJson(data);
    }
    throw const FormatException('Respuesta inesperada al actualizar producto');
  }

  @override
  Future<void> deleteProduct(String productId) async {
    await _client.delete('$_basePath/${Uri.encodeComponent(productId)}');
  }
}