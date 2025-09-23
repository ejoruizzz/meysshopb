import 'product.dart';

class CartItem {
  final Product product;
  final int qty;

  const CartItem({required this.product, required this.qty});

  CartItem copyWith({Product? product, int? qty}) =>
      CartItem(product: product ?? this.product, qty: qty ?? this.qty);

  double get subtotal => product.precio * qty;
}
