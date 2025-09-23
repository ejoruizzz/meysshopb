import '../models/product.dart';
import 'api_client.dart';
import 'product_repository.dart';

/// Implementación que consume la API REST de productos.
class ApiProductRepository implements ProductRepository {
  ApiProductRepository(
    this._client, {
    this.basePath = '/api/productos',
  });

  final ApiClient _client;
  final String basePath;

  final Map<String, String> _idCache = {};

  @override
  Future<List<Product>> fetchProducts({String? search}) async {
    final query = <String, dynamic>{};
    if (search != null && search.trim().isNotEmpty) {
      final value = search.trim();
      query['q'] = value;
      query['search'] = value;
    }

    final data = await _client.get(
      basePath,
      queryParameters: query.isEmpty ? null : query,
    );
    if (data is! List) {
      throw ApiException(
        500,
        'Respuesta inválida al listar productos',
        data: data,
      );
    }

    _idCache.clear();
    final products = <Product>[];
    for (final item in data) {
      if (item is! Map<String, dynamic>) continue;
      final product = Product.fromJson(item);
      products.add(product);
      _cacheId(product, item);
    }
    return products;
  }

  @override
  Future<Product> createProduct(Product p) async {
    final payload = _toJson(p)..remove('id');
    final data = await _client.post(basePath, body: payload);
    if (data is! Map<String, dynamic>) {
      throw ApiException(
        500,
        'Respuesta inválida al crear producto',
        data: data,
      );
    }
    final created = Product.fromJson(data);
    _cacheId(created, data);
    return created;
  }

  @override
  Future<Product> updateProduct(Product p) async {
    final id = _lookupId(p);
    if (id == null) {
      throw ApiException(
        400,
        'No se encontró identificador para el producto ${p.nombre}',
      );
    }
    final data = await _client.put('$basePath/$id', body: _toJson(p));
    if (data is! Map<String, dynamic>) {
      throw ApiException(
        500,
        'Respuesta inválida al actualizar producto',
        data: data,
      );
    }
    final updated = Product.fromJson(data);
    _cacheId(updated, data);
    return updated;
  }

  @override
  Future<void> deleteProduct(String productId) async {
    if (productId.trim().isEmpty) {
      throw ApiException(400, 'ID de producto inválido');
    }
    final normalized = productId.trim().toLowerCase();
    final id = _idCache[normalized] ?? _idCache[productId] ?? productId;
    await _client.delete('$basePath/$id');
    _idCache.removeWhere((_, value) => value == id);
  }

  void _cacheId(Product product, Map<String, dynamic> data) {
    final rawId = data['id'] ?? data['productoId'] ?? data['productId'];
    if (rawId == null) return;
    final id = rawId.toString();
    final keys = <String>{
      id,
      if (product.id != null && product.id!.isNotEmpty) product.id!,
      product.nombre.trim().toLowerCase(),
      '${product.nombre.trim().toLowerCase()}|${product.categoria.trim().toLowerCase()}',
    }..removeWhere((element) => element.isEmpty);
    for (final key in keys) {
      _idCache[key] = id;
    }
  }

  String? _lookupId(Product product) {
    if (product.id != null && product.id!.isNotEmpty) {
      return product.id;
    }
    final keys = <String>[
      product.nombre.trim().toLowerCase(),
      '${product.nombre.trim().toLowerCase()}|${product.categoria.trim().toLowerCase()}',
    ];
    for (final key in keys) {
      final id = _idCache[key];
      if (id != null) return id;
    }
    return null;
  }

  Map<String, dynamic> _toJson(Product product) => product.toJson();
}
