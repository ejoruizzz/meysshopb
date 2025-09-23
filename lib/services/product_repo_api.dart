import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

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

  Future<Product> createProduct(Product p, {File? imageFile}) async {
    if (imageFile == null) {
      throw ArgumentError('imageFile es obligatorio para crear productos');
    }

    final request = await _multipartRequest('POST', p, imageFile: imageFile);
    final data = await _client.post(basePath, body: request);

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
  Future<Product> updateProduct(Product p, {File? imageFile}) async {
    final id = _lookupId(p);
    if (id == null) {
      throw ApiException(
        400,
        'No se encontró identificador para el producto ${p.nombre}',
      );
    }
    final request = await _multipartRequest('PUT', p, imageFile: imageFile);
    final data = await _client.put('$basePath/$id', body: request);
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


  Future<http.MultipartRequest> _multipartRequest(
    String method,
    Product product, {
    File? imageFile,
  }) async {
    final request = http.MultipartRequest(method.toUpperCase(), Uri());
    request.fields.addAll(_formFields(product));

    if (imageFile != null) {
      final fileName = _fileName(imageFile.path);
      final mediaType = _mediaTypeForPath(imageFile.path);
      request.files.add(await http.MultipartFile.fromPath(
        'imagen',
        imageFile.path,
        filename: fileName,
        contentType: mediaType,
      ));
    }

    return request;
  }

  Map<String, String> _formFields(Product product) {
    final fields = <String, String>{
      'nombre': product.name.trim(),
      'apellido': product.lastName.trim(),
      'estado': product.estado.trim().isEmpty ? 'Activo' : product.estado.trim(),
      'price': product.price.toString(),
      'cantidad': product.cantidad.toString(),
    };

    void putIfNotEmpty(String key, String value) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        fields[key] = trimmed;
      }
    }

    putIfNotEmpty('email', product.email);
    putIfNotEmpty('telefono', product.phone);
    putIfNotEmpty('direccion', product.address);

    return fields;
  }

  String _fileName(String path) {
    final separator = Platform.pathSeparator;
    if (path.contains(separator)) {
      return path.split(separator).last;
    }
    return path.split('/').last;
  }

  MediaType? _mediaTypeForPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) {
      return MediaType('image', 'png');
    }
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return MediaType('image', 'jpeg');
    }
    return null;
  }

  Map<String, dynamic> _toJson(Product product) => product.toJson();

}
