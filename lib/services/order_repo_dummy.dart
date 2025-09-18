import 'dart:async';
import '../models/order.dart';
import '../models/order_status.dart';
import 'order_repository.dart';

/// Repositorio de pedidos en memoria (dummy).
class DummyOrderRepository implements OrderRepository {
  final List<Order> _orders;

  DummyOrderRepository(List<Order> initial) : _orders = List.from(initial);

  @override
  Future<List<Order>> fetchOrders({String? q, OrderStatus? status}) async {
    await Future.delayed(const Duration(milliseconds: 150)); // simula red

    final query = q?.toLowerCase().trim() ?? '';
    final list = _orders.where((o) {
      final matchesQuery = query.isEmpty ||
          o.id.toLowerCase().contains(query) ||
          o.customerName.toLowerCase().contains(query) ||
          o.customerEmail.toLowerCase().contains(query);
      final matchesStatus = status == null || o.status == status;
      return matchesQuery && matchesStatus;
    }).toList();

    // Ordenar de más reciente a más antiguo
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<void> updateStatus(String orderId, OrderStatus newStatus) async {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx == -1) throw Exception('Pedido no encontrado');
    final old = _orders[idx];
    _orders[idx] = old.copyWith(status: newStatus);
  }

  @override
  Future<Order> createOrder(Order o) async {
    // Si el id ya existe, lanza error
    if (_orders.any((p) => p.id == o.id)) {
      throw Exception('Ya existe un pedido con id ${o.id}');
    }
    _orders.add(o);
    return o;
  }
}
