import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

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

  @override
  Future<List<Product>> fetchProducts({String? search}) async {
    final query = <String, dynamic>{};
    if (search != null && search.trim().isNotEmpty) {
      query['q'] = search.trim();
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

    _idByCacheKey.clear();
    final products = <Product>[];
    for (final item in data) {
      if (item is! Map<String, dynamic>) continue;
      final product = _fromJson(item);
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
    if (data is! Map<String, dynamic>) {
      throw ApiException(
        500,
        'Respuesta inválida al crear producto',
        data: data,
      );
    }
    final created = _fromJson(data);
    _cacheId(created, data);
    return created;
  }

  @override
  Future<Product> updateProduct(Product p, {File? imageFile}) async {
    final id = _lookupId(p);
    if (id == null) {
      throw ApiException(
        400,
        'No se encontró identificador para el producto ${p.name}',
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
    final updated = _fromJson(data);
    _cacheId(updated, data);
    return updated;
  }

  @override
  Future<void> deleteProduct(String productId) async {
    final id =
        productId.isNotEmpty ? (_idByCacheKey[productId] ?? productId) : null;
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

  String _cacheKey(Product product) {
    final fullName = [product.name, product.lastName]
        .where((element) => element.isNotEmpty)
        .join(' ')
        .trim();
    return (fullName.isEmpty ? product.name : fullName).toLowerCase();
  }

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
      id: json['id']?.toString(),
      name: _string(json['nombre'] ?? json['name']),
      lastName: _string(json['apellido'] ?? json['lastName']),
      email: _string(json['email'] ?? json['correo']),
      phone: _string(json['telefono'] ?? json['phone']),
      address: _string(json['direccion'] ?? json['address']),
      price: _double(json['price']),
      imageUrl: _string(json['imageUrl'] ?? json['imagen']),
      cantidad: _int(json['cantidad'] ?? json['stock']),
      estado: _string(json['estado'], 'Activo'),
    );
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
}
