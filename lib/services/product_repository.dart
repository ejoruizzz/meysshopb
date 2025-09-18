import '../models/product.dart';

/// Contrato de acceso a productos.
/// La UI solo debería depender de esta interfaz.
abstract class ProductRepository {
  /// Lista productos (opcional: búsqueda por nombre).
  Future<List<Product>> fetchProducts({String? search});

  /// Crea un producto y devuelve el creado.
  Future<Product> createProduct(Product p);

  /// Actualiza un producto y devuelve el guardado.
  Future<Product> updateProduct(Product p);

  /// Elimina un producto por su identificador.
  /// En dummy usaremos `name` como llave temporal.
  Future<void> deleteProduct(String productId);
}
