import '../models/order.dart';
import '../models/order_status.dart';
import 'api_client.dart';
import 'order_repository.dart';

class ApiOrderRepository implements OrderRepository {
  ApiOrderRepository(this._client);

  final ApiClient _client;
  static const String _basePath = '/api/pedidos';

  @override
  Future<List<Order>> fetchOrders({String? q, OrderStatus? status}) async {
    final query = <String, dynamic>{};
    if (q != null && q.trim().isNotEmpty) {
      query['q'] = q.trim();
    }
    if (status != null) {
      query['status'] = status.apiValue;
    }
    final data = await _client.get(
      _basePath,
      queryParameters: query.isEmpty ? null : query,
    );
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(Order.fromJson)
          .toList(growable: false);
    }
    throw const FormatException('Respuesta inesperada al listar pedidos');
  }

  @override
  Future<void> updateStatus(String orderId, OrderStatus newStatus) async {
    await _client.patch(
      '$_basePath/${Uri.encodeComponent(orderId)}/status',
      body: {'status': newStatus.apiValue},
    );
  }

  @override
  Future<Order> createOrder(Order o) async {
    final data = await _client.post(_basePath, body: o.toJson());
    if (data is Map<String, dynamic>) {
      return Order.fromJson(data);
    }
    throw const FormatException('Respuesta inesperada al crear pedido');
  }
}