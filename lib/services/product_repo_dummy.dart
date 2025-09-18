import 'dart:async';
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
        .where((p) => p.name.toLowerCase().contains(q))
        .toList(growable: false);
  }

  @override
  Future<Product> createProduct(Product p) async {
    bool _sameIdentity(Product a, Product b) {
      if (a.id != null && b.id != null) {
        return a.id == b.id;
      }
      return a.name.toLowerCase() == b.name.toLowerCase();
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
  Future<Product> updateProduct(Product p) async {
    int _indexOf(Product product) {
      if (product.id != null) {
        final idx = _store.indexWhere((x) => x.id == product.id);
        if (idx != -1) return idx;
      }
      return _store.indexWhere((x) => x.name.toLowerCase() == product.name.toLowerCase());
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
      return x.name.toLowerCase() == productId.toLowerCase();
    });
    if (_store.length == before) {
      throw Exception('Producto no encontrado');
    }
  }

}
