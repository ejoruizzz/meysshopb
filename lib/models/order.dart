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

  factory Order.fromJson(Map<String, dynamic> json) {
    DateTime _readDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (_) {
          return DateTime.now();
        }
      }
      if (value is int) {
        // Asumimos milisegundos
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      return DateTime.now();
    }

    List<OrderItem> _readItems(dynamic value) {
      if (value is List) {
        return value
            .whereType<Map<String, dynamic>>()
            .map(OrderItem.fromJson)
            .toList(growable: false);
      }
      return const <OrderItem>[];
    }

    String _readString(dynamic value, {String fallback = ''}) {
      if (value is String) return value;
      if (value == null) return fallback;
      return value.toString();
    }

    final id = _readString(json['id']);
    if (id.isEmpty) {
      throw const FormatException('Order JSON sin "id"');
    }

    final customerId = _readString(json['customerId'] ?? json['clienteId'] ?? json['userId']);
    if (customerId.isEmpty) {
      throw const FormatException('Order JSON sin "customerId"');
    }

    final customerName = _readString(json['customerName'] ?? json['clienteNombre'] ?? json['nombreCliente']);
    final customerEmail = _readString(json['customerEmail'] ?? json['clienteEmail']);

    return Order(
      id: id,
      customerId: customerId,
      customerName: customerName,
      customerEmail: customerEmail,
      createdAt: _readDate(json['createdAt'] ?? json['fecha'] ?? json['created_at']),
      status: orderStatusFromApiValue(_readString(json['status'] ?? json['estado'], fallback: 'pending')),
      items: _readItems(json['items'] ?? json['detalle'] ?? json['products']),
      notes: (json['notes'] ?? json['notas'] ?? json['comentarios']) as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'createdAt': createdAt.toIso8601String(),
      'status': status.apiValue,
      'items': items.map((it) => it.toJson()).toList(),
      if (notes != null) 'notes': notes,
    };
  }

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
