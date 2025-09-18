import '../models/product.dart';
import 'api_client.dart';
import 'product_repository.dart';


/// Implementación que consume la API REST (por ahora /api/clientes).
class ApiProductRepository implements ProductRepository {
  ApiProductRepository(
    this._client, {
    this.basePath = '/api/clientes',
  });

  final ApiClient _client;
  final String basePath;

  final Map<String, String> _idByCacheKey = {};

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


    final data = await _client.get(basePath, queryParameters: query.isEmpty ? null : query);
    if (data is! List) {
      throw ApiException(500, 'Respuesta inválida al listar productos', data: data);
    }

    _idByCacheKey.clear();
    final products = <Product>[];
    for (final item in data) {
      if (item is! Map<String, dynamic>) continue;
      final product = _fromJson(item);
      products.add(product);
      _cacheId(product, item);
    }
    return products;

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

    final data = await _client.post(basePath, body: _toJson(p));
    if (data is! Map<String, dynamic>) {
      throw ApiException(500, 'Respuesta inválida al crear producto', data: data);
    }
    final created = _fromJson(data);
    _cacheId(created, data);
    return created;

    final payload = p.toJson();
    final data = await _client.post(_basePath, body: payload);
    if (data is Map<String, dynamic>) {
      return Product.fromJson(data);
    }
    throw const FormatException('Respuesta inesperada al crear producto');

  }

  @override
  Future<Product> updateProduct(Product p) async {

    final id = _lookupId(p);
    if (id == null) {
      throw ApiException(400, 'No se encontró identificador para el producto ${p.name}');
    }
    final data = await _client.put('$basePath/$id', body: _toJson(p));
    if (data is! Map<String, dynamic>) {
      throw ApiException(500, 'Respuesta inválida al actualizar producto', data: data);
    }
    final updated = _fromJson(data);
    _cacheId(updated, data);
    return updated;

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

    final id = productId.isNotEmpty ? (_idByCacheKey[productId] ?? productId) : null;
    if (id == null) {
      throw ApiException(400, 'ID de producto inválido');
    }
    await _client.delete('$basePath/$id');
    _idByCacheKey.removeWhere((_, value) => value == id);
  }

  void _cacheId(Product product, Map<String, dynamic> data) {
    final rawId = data['id'];
    if (rawId == null) return;
    final id = rawId.toString();
    _idByCacheKey[_cacheKey(product)] = id;
    _idByCacheKey[id] = id;
  }

  String? _lookupId(Product product) {
    final key = _cacheKey(product);
    return _idByCacheKey[key];
  }

  String _cacheKey(Product product) => product.name.toLowerCase();

  Product _fromJson(Map<String, dynamic> json) {
    double _double(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0;
      return 0;
    }

    int _int(dynamic value) {
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    String _string(dynamic value, [String fallback = '']) {
      if (value is String) return value;
      return value?.toString() ?? fallback;
    }

    return Product(
      name: _string(json['name'] ?? json['nombre']),
      price: _double(json['price']),
      imageUrl: _string(json['imageUrl'] ?? json['imagen']),
      cantidad: _int(json['cantidad'] ?? json['stock']),
      estado: _string(json['estado'], 'Activo'),
    );
  }

  Map<String, dynamic> _toJson(Product product) => {
        'name': product.name,
        'price': product.price,
        'imageUrl': product.imageUrl,
        'cantidad': product.cantidad,
        'estado': product.estado,
      };

    await _client.delete('$_basePath/${Uri.encodeComponent(productId)}');
  }

}