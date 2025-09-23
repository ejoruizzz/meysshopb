import 'product.dart';

class OrderItem {
  final Product productSnapshot; // snapshot del producto al momento del pedido
  final int qty;

  const OrderItem({
    required this.productSnapshot,
    required this.qty,
  });

  double get subtotal => productSnapshot.precio * qty;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final productJson = json['productSnapshot'] ?? json['product'] ?? json['producto'];
    if (productJson is! Map<String, dynamic>) {
      throw const FormatException('OrderItem JSON sin producto');
    }

    int _readQty(dynamic value) {
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return OrderItem(
      productSnapshot: Product.fromJson(productJson),
      qty: _readQty(json['qty'] ?? json['cantidad'] ?? json['quantity']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productSnapshot': productSnapshot.toJson(),
      'qty': qty,
    };
  }
}
