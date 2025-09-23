import 'dart:async';
import 'dart:io';

import '../models/product.dart';
import 'product_repository.dart';

/// Repositorio en memoria para DEMO/MVP.
/// Nota: como tu Product aún no tiene `id`, usamos `name` como “llave” temporal.
/// Cuando agregues `id`, cambia los métodos para usarlo.
class DummyProductRepository implements ProductRepository {
  final List<Product> _store;

  /// Pasa una lista inicial de productos (por ejemplo los de main.dart).
  DummyProductRepository(List<Product> initial) : _store = List.from(initial);

  @override
  Future<List<Product>> fetchProducts({String? search}) async {
    await Future.delayed(const Duration(milliseconds: 150)); // micro delay demo
    if (search == null || search.trim().isEmpty) {
      // Devolvemos copia inmutable para evitar mutaciones externas
      return List<Product>.unmodifiable(_store);
    }
    final q = search.toLowerCase();
    return _store
        .where((p) {
          final fullName = [p.name, p.lastName]
              .where((element) => element.isNotEmpty)
              .join(' ')
              .trim()
              .toLowerCase();
          return fullName.contains(q);
        })
        .toList(growable: false);
  }

  @override
  Future<Product> createProduct(Product p, {File? imageFile}) async {
    bool _sameIdentity(Product a, Product b) {
      if (a.id != null && b.id != null) {
        return a.id == b.id;
      }
      String _fullName(Product product) =>
          [product.name, product.lastName]
              .where((element) => element.isNotEmpty)
              .join(' ')
              .trim()
              .toLowerCase();
      return _fullName(a) == _fullName(b);
    }

    // Evita duplicados por id (si existe) o por nombre en modo dummy
    final exists = _store.any((x) => _sameIdentity(x, p));
    if (exists) {
      throw Exception('Ya existe un producto con ese nombre');
    }
    _store.add(p);
    return p;
  }

  @override
  Future<Product> updateProduct(Product p, {File? imageFile}) async {
    int _indexOf(Product product) {
      if (product.id != null) {
        final idx = _store.indexWhere((x) => x.id == product.id);
        if (idx != -1) return idx;
      }
      String _fullName(Product product) =>
          [product.name, product.lastName]
              .where((element) => element.isNotEmpty)
              .join(' ')
              .trim()
              .toLowerCase();
      final target = _fullName(product);
      return _store.indexWhere((x) => _fullName(x) == target);
    }

    final idx = _indexOf(p);
    if (idx == -1) throw Exception('Producto no encontrado');
    _store[idx] = p;
    return p;
  }

  @override
  Future<void> deleteProduct(String productId) async {
    final before = _store.length;
    _store.removeWhere((x) {
      if (x.id != null && x.id == productId) {
        return true;
      }
      final fullName =
          [x.name, x.lastName].where((element) => element.isNotEmpty).join(' ').trim().toLowerCase();
      return fullName == productId.toLowerCase();
    });
    if (_store.length == before) {
      throw Exception('Producto no encontrado');
    }
  }

}
