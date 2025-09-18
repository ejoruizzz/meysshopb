import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/order.dart';
import '../models/order_status.dart';

class AdminOrdersScreen extends StatefulWidget {
  final List<Order> orders;
  final void Function(String orderId, OrderStatus newStatus) onUpdateStatus;
  final bool showAppBar; // <- NUEVO (por defecto true)

  const AdminOrdersScreen({
    super.key,
    required this.orders,
    required this.onUpdateStatus,
    this.showAppBar = true,
  });

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  String _query = "";
  OrderStatus? _filter;

  List<Order> get _filtered {
    final list = widget.orders.where((o) {
      final matchesQuery = _query.isEmpty ||
          o.id.toLowerCase().contains(_query.toLowerCase()) ||
          o.customerName.toLowerCase().contains(_query.toLowerCase()) ||
          o.customerEmail.toLowerCase().contains(_query.toLowerCase());
      final matchesStatus = _filter == null || o.status == _filter;
      return matchesQuery && matchesStatus;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> _exportCsv() async {
    final rows = <String>[];
    rows.add("id,cliente,correo,estado,total,fecha");
    for (final o in _filtered) {
      final id = _csvEscape(o.id);
      final cliente = _csvEscape(o.customerName);
      final correo = _csvEscape(o.customerEmail);
      final estado = _csvEscape(o.status.label);
      final total = o.total.toStringAsFixed(2);
      final fecha = _csvEscape(_isoLike(o.createdAt));
      rows.add("$id,$cliente,$correo,$estado,$total,$fecha");
    }
    final csv = rows.join("\n");
    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/pedidos_export.csv");
    await file.writeAsString(csv, flush: true);
    await Share.shareXFiles([XFile(file.path)],
        text: "Exportación de pedidos", subject: "Pedidos (.csv)");
  }

  static String _csvEscape(String v) {
    if (v.contains(',') || v.contains('"') || v.contains('\n')) {
      return '"${v.replaceAll('"', '""')}"';
    }
    return v;
  }

  static String _isoLike(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return "$y-$m-$d $hh:$mm";
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    final content = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: TextField(
            decoration: InputDecoration(
              hintText: "Buscar por ID, cliente o correo...",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              FilterChip(
                label: const Text("Todos"),
                selected: _filter == null,
                onSelected: (_) => setState(() => _filter = null),
              ),
              const SizedBox(width: 8),
              ...OrderStatus.values.map((s) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(s.label),
                      selected: _filter == s,
                      onSelected: (_) => setState(() => _filter = s),
                    ),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text("No hay pedidos con esos filtros"))
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final order = filtered[index];
                    return _OrderCard(
                      order: order,
                      onUpdateStatus: widget.onUpdateStatus,
                    );
                  },
                ),
        ),
      ],
    );

    final bottomBar = SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _exportCsv,
                icon: const Icon(Icons.file_download),
                label: const Text("Exportar CSV"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: filtered.isEmpty
                    ? null
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Pedidos listados: ${filtered.length}")),
                        );
                      },
                icon: const Icon(Icons.select_all),
                label: const Text("Acciones"),
              ),
            ),
          ],
        ),
      ),
    );

    // Si showAppBar == true, mostramos AppBar (modo pantalla independiente).
    // Si showAppBar == false, se usa el AppBar del Scaffold padre (MainScreen tab).
    return Scaffold(
      appBar: widget.showAppBar ? AppBar(title: const Text("Pedidos")) : null,
      body: content,
      bottomNavigationBar: bottomBar,
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final void Function(String orderId, OrderStatus newStatus) onUpdateStatus;

  const _OrderCard({
    required this.order,
    required this.onUpdateStatus,
  });

  Color _statusColor(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending:   return Colors.orange;
      case OrderStatus.preparing: return Colors.blue;
      case OrderStatus.shipped:   return Colors.purple;
      case OrderStatus.completed: return Colors.green;
      case OrderStatus.cancelled: return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: _statusColor(order.status).withOpacity(0.15),
                child: Icon(Icons.receipt_long, color: _statusColor(order.status)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("#${order.id}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(order.customerName),
                    const SizedBox(height: 2),
                    Text(order.customerEmail, style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 6),
                    Text(
                      "${order.items.length} artículo(s) • \$${order.total.toStringAsFixed(2)}",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Creado: ${_friendlyDate(order.createdAt)}",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _StatusPill(
                status: order.status,
                color: _statusColor(order.status),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<OrderStatus>(
                onSelected: (s) => onUpdateStatus(order.id, s),
                itemBuilder: (context) => [
                  for (final s in OrderStatus.values)
                    PopupMenuItem(value: s, child: Text("Marcar como ${s.label}")),
                ],
                icon: const Icon(Icons.more_vert),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
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
                      const Icon(Icons.receipt_long, color: Colors.pink),
                      const SizedBox(width: 8),
                      Text(
                        "Pedido #${order.id}",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      _StatusPill(status: order.status, color: _statusColor(order.status)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text("Cliente: ${order.customerName}"),
                  Text("Correo: ${order.customerEmail}", style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text("Artículos", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  for (final it in order.items)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(it.productSnapshot.name),
                      subtitle: Text("Cantidad: ${it.qty} • \$${it.productSnapshot.price.toStringAsFixed(2)}"),
                      trailing: Text(
                        "\$${it.subtotal.toStringAsFixed(2)}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(
                        "\$${order.total.toStringAsFixed(2)}",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.pink),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (order.notes != null && order.notes!.trim().isNotEmpty) ...[
                    const Text("Notas:", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(order.notes!, style: const TextStyle(color: Colors.black87)),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                    label: const Text("Cerrar"),
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
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return "$d/$m $hh:$mm";
  }
}

class _StatusPill extends StatelessWidget {
  final OrderStatus status;
  final Color color;

  const _StatusPill({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(status.label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
  }
}
