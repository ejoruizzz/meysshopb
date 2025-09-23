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

    final query = search.toLowerCase();
    return _store
        .where((product) {
          final searchableValues = <String>[
            product.nombre,
            product.descripcion,
            product.categoria,
            product.imagenUrl,
          ]
              .where((value) => value.trim().isNotEmpty)
              .map((value) => value.toLowerCase());

          if (searchableValues.any((value) => value.contains(query))) {
            return true;
          }

          return product.stock.toString().contains(query);
        })
        .toList(growable: false);
  }

  @override
  Future<Product> createProduct(Product p, {File? imageFile}) async {
    bool sameIdentity(Product a, Product b) {
      if (a.id != null && b.id != null) {
        return a.id == b.id;
      }
      final nameA = a.nombre.trim().toLowerCase();
      final nameB = b.nombre.trim().toLowerCase();
      if (nameA != nameB) return false;
      final catA = a.categoria.trim().toLowerCase();
      final catB = b.categoria.trim().toLowerCase();
      if (catA.isEmpty || catB.isEmpty) return true;
      return catA == catB;
    }

    // Evita duplicados por id (si existe) o por nombre/categoría en modo dummy
    final exists = _store.any((x) => sameIdentity(x, p));
    if (exists) {
      throw Exception('Ya existe un producto con ese nombre');
    }
    _store.add(p);
    return p;
  }

  @override
  Future<Product> updateProduct(Product p, {File? imageFile}) async {
    int indexOf(Product product) {
      if (product.id != null) {
        final idx = _store.indexWhere((x) => x.id == product.id);
        if (idx != -1) return idx;
      }
      final name = product.nombre.trim().toLowerCase();
      final category = product.categoria.trim().toLowerCase();
      return _store.indexWhere((x) {
        final sameName = x.nombre.trim().toLowerCase() == name;
        if (!sameName) return false;
        if (category.isEmpty) return true;
        final cat = x.categoria.trim().toLowerCase();
        return cat == category;
      });
    }

    final idx = indexOf(p);
    if (idx == -1) throw Exception('Producto no encontrado');
    _store[idx] = p;
    return p;
  }

  @override
  Future<void> deleteProduct(String productId) async {
    final before = _store.length;
    final normalized = productId.trim().toLowerCase();
    _store.removeWhere((x) {
      if (x.id != null && x.id == productId) {
        return true;
      }
      final name = x.nombre.trim().toLowerCase();
      if (name == normalized) return true;
      final catKey = '$name|${x.categoria.trim().toLowerCase()}';
      return catKey == normalized;
    });
    if (_store.length == before) {
      throw Exception('Producto no encontrado');
    }
  }
}
