import 'product.dart';

class OrderItem {
  final Product productSnapshot; // snapshot del producto al momento del pedido
  final int qty;

  const OrderItem({
    required this.productSnapshot,
    required this.qty,
  });

  double get subtotal => productSnapshot.price * qty;
}
