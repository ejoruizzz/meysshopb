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
    // Evita duplicados por “name” en el dummy
    final exists = _store.any((x) => x.name.toLowerCase() == p.name.toLowerCase());
    if (exists) {
      throw Exception('Ya existe un producto con ese nombre');
    }
    _store.add(p);
    return p;
  }

  @override
  Future<Product> updateProduct(Product p) async {
    // Busca por “name”; en producción sería por id
    final idx = _store.indexWhere((x) => x.name.toLowerCase() == p.name.toLowerCase());
    if (idx == -1) throw Exception('Producto no encontrado');
    _store[idx] = p;
    return p;
  }

  @override
Future<void> deleteProduct(String productId) async {
  final before = _store.length;
  _store.removeWhere(
    (x) => x.name.toLowerCase() == productId.toLowerCase(),
  );
  if (_store.length == before) {
    throw Exception('Producto no encontrado');
  }
}

}
