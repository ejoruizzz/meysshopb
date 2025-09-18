import '../models/order.dart';
import '../models/order_status.dart';

/// Contrato para gestionar pedidos.
abstract class OrderRepository {
  /// Lista pedidos; puedes filtrar por búsqueda y estado.
  Future<List<Order>> fetchOrders({String? q, OrderStatus? status});

  /// Actualiza el estado de un pedido (ej. pendiente → enviado).
  Future<void> updateStatus(String orderId, OrderStatus newStatus);

  /// Crea un nuevo pedido y lo devuelve.
  Future<Order> createOrder(Order o);
}
