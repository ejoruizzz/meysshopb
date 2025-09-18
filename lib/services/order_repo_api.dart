import '../models/order.dart';
import '../models/order_item.dart';
import '../models/order_status.dart';
import '../models/product.dart';
import 'api_client.dart';
import 'order_repository.dart';

class ApiOrderRepository implements OrderRepository {
  ApiOrderRepository(
    this._client, {
    this.basePath = '/api/orders',
  });

  final ApiClient _client;
  final String basePath;

  @override
  Future<List<Order>> fetchOrders({String? q, OrderStatus? status}) async {
    final query = <String, dynamic>{};
    if (q != null && q.trim().isNotEmpty) query['q'] = q.trim();
    if (status != null) query['status'] = _statusToString(status);

    final data = await _client.get(basePath, queryParameters: query.isEmpty ? null : query);
    if (data is! List) {
      throw ApiException(500, 'Respuesta inválida al listar pedidos', data: data);
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(_orderFromJson)
        .toList(growable: false);
  }

  @override
  Future<void> updateStatus(String orderId, OrderStatus newStatus) async {
    await _client.patch(
      '$basePath/$orderId',
      body: {'status': _statusToString(newStatus)},
    );
  }

  @override
  Future<Order> createOrder(Order o) async {
    final data = await _client.post(basePath, body: _orderToJson(o));
    if (data is! Map<String, dynamic>) {
      throw ApiException(500, 'Respuesta inválida al crear pedido', data: data);
    }
    return _orderFromJson(data);
  }

  Order _orderFromJson(Map<String, dynamic> json) {
    OrderStatus _statusFrom(String? value) {
      switch (value) {
        case 'pending':
          return OrderStatus.pending;
        case 'preparing':
          return OrderStatus.preparing;
        case 'shipped':
          return OrderStatus.shipped;
        case 'completed':
          return OrderStatus.completed;
        case 'cancelled':
          return OrderStatus.cancelled;
        default:
          return OrderStatus.pending;
      }
    }

    DateTime _parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) return parsed;
      }
      if (value is num) {
        return DateTime.fromMillisecondsSinceEpoch(value.toInt());
      }
      return DateTime.now();
    }

    List<OrderItem> _itemsFrom(dynamic raw) {
      if (raw is! List) return const <OrderItem>[];
      return raw.whereType<Map<String, dynamic>>().map((item) {
        final productJson = (item['productSnapshot'] ?? item['product']) as Map<String, dynamic>?;
        final product = productJson != null ? _productFromJson(productJson) : _emptyProduct();
        final qty = item['qty'] is num
            ? (item['qty'] as num).toInt()
            : int.tryParse(item['qty']?.toString() ?? '') ?? 0;
        return OrderItem(productSnapshot: product, qty: qty);
      }).toList(growable: false);
    }

    return Order(
      id: json['id']?.toString() ?? '',
      customerId: json['customerId']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? '',
      customerEmail: json['customerEmail']?.toString() ?? '',
      createdAt: _parseDate(json['createdAt']),
      status: _statusFrom(json['status']?.toString()),
      items: _itemsFrom(json['items']),
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> _orderToJson(Order order) {
    final json = <String, dynamic>{
      'customerId': order.customerId,
      'customerName': order.customerName,
      'customerEmail': order.customerEmail,
      'createdAt': order.createdAt.toIso8601String(),
      'status': _statusToString(order.status),
      'items': order.items
          .map((it) => {
                'product': _productToJson(it.productSnapshot),
                'qty': it.qty,
              })
          .toList(growable: false),
    };
    if (order.id.isNotEmpty) {
      json['id'] = order.id;
    }
    if (order.notes != null) {
      json['notes'] = order.notes;
    }
    return json;
  }

  String _statusToString(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.preparing:
        return 'preparing';
      case OrderStatus.shipped:
        return 'shipped';
      case OrderStatus.completed:
        return 'completed';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }

  Product _productFromJson(Map<String, dynamic> json) {
    double _double(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0;
      return 0;
    }

    int _int(dynamic value) {
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    String _string(dynamic value, [String fallback = '']) {
      if (value is String) return value;
      return value?.toString() ?? fallback;
    }

    return Product(
      name: _string(json['name'] ?? json['nombre']),
      price: _double(json['price']),
      imageUrl: _string(json['imageUrl'] ?? json['imagen']),
      cantidad: _int(json['cantidad'] ?? json['stock']),
      estado: _string(json['estado'] ?? 'Activo'),
    );
  }

  Product _emptyProduct() => const Product(
        name: '',
        price: 0,
        imageUrl: '',
        cantidad: 0,
        estado: 'Activo',
      );

  Map<String, dynamic> _productToJson(Product product) => {
        'name': product.name,
        'price': product.price,
        'imageUrl': product.imageUrl,
        'cantidad': product.cantidad,
        'estado': product.estado,
      };
}