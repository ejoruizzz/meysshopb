import 'package:flutter/material.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/order_status.dart';

class OrderHistoryScreen extends StatefulWidget {
  final String customerId; // filtramos por userId (no por email)
  final List<Order> allOrders;
  final void Function(List<OrderItem> items) onReorder; // re-agregar al carrito

  const OrderHistoryScreen({
    super.key,
    required this.customerId,
    required this.allOrders,
    required this.onReorder,
  });

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  String _query = "";
  OrderStatus? _statusFilter;
  int _daysFilter = 0; // 0: todo, 7, 30

  List<Order> get _filtered {
    final now = DateTime.now();
    final after = (_daysFilter == 0)
        ? DateTime(2000)
        : DateTime(now.year, now.month, now.day).subtract(Duration(days: _daysFilter - 1));

    final list = widget.allOrders.where((o) {
      if (o.customerId != widget.customerId) return false;
      final byDate = o.createdAt.isAfter(after) || o.createdAt.isAtSameMomentAs(after);
      final byStatus = _statusFilter == null || o.status == _statusFilter;
      final q = _query.trim().toLowerCase();
      final byQuery = q.isEmpty ||
          o.id.toLowerCase().contains(q) ||
          o.customerName.toLowerCase().contains(q);
      return byDate && byStatus && byQuery;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final orders = _filtered;
    return Scaffold(
      appBar: AppBar(title: const Text("Historial de compras")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Buscar por ID o nombre...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          // filtros rápidos
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                FilterChip(
                  label: const Text("Todos"),
                  selected: _statusFilter == null,
                  onSelected: (_) => setState(() => _statusFilter = null),
                ),
                const SizedBox(width: 8),
                ...OrderStatus.values.map((s) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(s.label),
                        selected: _statusFilter == s,
                        onSelected: (_) => setState(() => _statusFilter = s),
                      ),
                    )),
                const SizedBox(width: 8),
                const Text("Rango: "),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text("Todo"),
                  selected: _daysFilter == 0,
                  onSelected: (_) => setState(() => _daysFilter = 0),
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text("7 días"),
                  selected: _daysFilter == 7,
                  onSelected: (_) => setState(() => _daysFilter = 7),
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text("30 días"),
                  selected: _daysFilter == 30,
                  onSelected: (_) => setState(() => _daysFilter = 30),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: orders.isEmpty
                ? const Center(child: Text("No hay pedidos con esos filtros"))
                : ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final o = orders[index];
                      return Card(
                        margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                        child: ListTile(
                          title: Text("#${o.id} • \$${o.total.toStringAsFixed(2)}"),
                          subtitle: Text(_friendlyDate(o.createdAt)),
                          trailing: _StatusPill(status: o.status),
                          onTap: () => _showDetails(o),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showDetails(Order o) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (ctx, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: ListView(
                controller: scrollController,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shopping_bag, color: Colors.pink),
                      const SizedBox(width: 8),
                      Text("Pedido #${o.id}",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      _StatusPill(status: o.status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text("Fecha: ${_friendlyDate(o.createdAt)}"),
                  const Divider(),
                  const Text("Artículos", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  for (final it in o.items)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(it.productSnapshot.name),
                      subtitle: Text(
                          "Cantidad: ${it.qty} • \$${it.productSnapshot.price.toStringAsFixed(2)}"),
                      trailing: Text("\$${it.subtotal.toStringAsFixed(2)}",
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text("\$${o.total.toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.pink)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                          },
                          icon: const Icon(Icons.close),
                          label: const Text("Cerrar"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            widget.onReorder(o.items);
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Productos del pedido añadidos al carrito (si hay stock)")),
                            );
                          },
                          icon: const Icon(Icons.replay),
                          label: const Text("Comprar de nuevo"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static String _friendlyDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return "$d/$m/$y $hh:$mm";
  }
}

class _StatusPill extends StatelessWidget {
  final OrderStatus status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    Color c;
    switch (status) {
      case OrderStatus.pending:   c = Colors.orange; break;
      case OrderStatus.preparing: c = Colors.blue;   break;
      case OrderStatus.shipped:   c = Colors.purple; break;
      case OrderStatus.completed: c = Colors.green;  break;
      case OrderStatus.cancelled: c = Colors.red;    break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: c.withOpacity(0.4)),
      ),
      child: Text(
        {
          OrderStatus.pending: "Pendiente",
          OrderStatus.preparing: "Preparando",
          OrderStatus.shipped: "Enviado",
          OrderStatus.completed: "Completado",
          OrderStatus.cancelled: "Cancelado",
        }[status]!,
        style: TextStyle(color: c, fontWeight: FontWeight.w600),
      ),
    );
  }
}
