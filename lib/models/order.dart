import 'order_item.dart';
import 'order_status.dart';

class Order {
  final String id;
  final String customerId;      // 👈 clave para enlazar con Usuario (email puede cambiar)
  final String customerName;    // snapshot legible
  final String customerEmail;   // snapshot legible
  final DateTime createdAt;
  final OrderStatus status;
  final List<OrderItem> items;
  final String? notes;

  const Order({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    required this.createdAt,
    required this.status,
    required this.items,
    this.notes,
  });

  double get total => items.fold(0, (sum, it) => sum + it.subtotal);

  Order copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerEmail,
    DateTime? createdAt,
    OrderStatus? status,
    List<OrderItem>? items,
    String? notes,
  }) {
    return Order(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      items: items ?? this.items,
      notes: notes ?? this.notes,
    );
  }
}
