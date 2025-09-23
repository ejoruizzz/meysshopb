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
    final body = imageFile != null
        ? await _multipartRequest('POST', p, imageFile: imageFile)
        : (_requestPayload(p)..remove('id'));

    final data = await _client.post(basePath, body: body);

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
    final body = imageFile != null
        ? await _multipartRequest('PUT', p,
            imageFile: imageFile, idOverride: id)
        : _requestPayload(p, idOverride: id);
    final data = await _client.put('$basePath/$id', body: body);
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
    String? idOverride,
  }) async {
    final request = http.MultipartRequest(method.toUpperCase(), Uri());
    request.fields.addAll(_formFields(product, idOverride: idOverride));

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

  Map<String, String> _formFields(
    Product product, {
    String? idOverride,
  }) {
    final payload = _requestPayload(product, idOverride: idOverride);
    return payload.map((key, value) => MapEntry(key, value.toString()));
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

  Map<String, dynamic> _requestPayload(
    Product product, {
    String? idOverride,
  }) {
    final fields = <String, dynamic>{};

    String? normalized(String? value) {
      if (value == null) return null;
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    final idValue = normalized(idOverride ?? product.id);
    if (idValue != null) {
      fields['id'] = idValue;
      fields['productoId'] = idValue;
      fields['productId'] = idValue;
    }

    final nombre = normalized(product.nombre);
    if (nombre != null) {
      fields['nombre'] = nombre;
      fields['name'] = nombre;
    }

    final descripcion = normalized(product.descripcion);
    if (descripcion != null) {
      fields['descripcion'] = descripcion;
      fields['description'] = descripcion;
    }

    fields['precio'] = product.precio;
    fields['price'] = product.precio;

    fields['stock'] = product.stock;
    fields['cantidad'] = product.stock;

    final categoria = normalized(product.categoria);
    if (categoria != null) {
      fields['categoria'] = categoria;
      fields['category'] = categoria;
    }

    final imagenUrl = normalized(product.imagenUrl);
    if (imagenUrl != null) {
      fields['imagenUrl'] = imagenUrl;
      fields['imageUrl'] = imagenUrl;
      fields['imagen_url'] = imagenUrl;
    }

    return fields;
  }

}
