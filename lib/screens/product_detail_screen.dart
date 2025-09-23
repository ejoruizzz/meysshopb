import 'package:flutter/material.dart';
import '../models/product.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final bool isAdmin; // controla visibilidad del stock y compra
  final void Function(Product, int qty)? onAddToCart; // qty

  const ProductDetailScreen({
    super.key,
    required this.product,
    this.isAdmin = false,
    this.onAddToCart,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late int _qty;

  @override
  void initState() {
    super.initState();
    _qty = widget.product.cantidad > 0 ? 1 : 0; // 0 si sin stock
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final fullName = [p.name, p.lastName].where((it) => it.isNotEmpty).join(' ').trim();
    final bool showForClient = !widget.isAdmin && p.cantidad < 5;
    final bool showForAdmin  = widget.isAdmin;
    final bool lowForAdmin   = p.cantidad < 10;

    final Color stockColor = widget.isAdmin
        ? (lowForAdmin ? Colors.red : Colors.green)
        : Colors.red; // cliente solo lo ve si <5

    final bool outOfStock = p.cantidad <= 0;

    Widget infoRow(IconData icon, String label, String value) {
      if (value.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.pink.shade400),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(fullName.isEmpty ? p.name : fullName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                p.imageUrl,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, _, __) => Container(
                  height: 250,
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              fullName.isEmpty ? p.name : fullName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "\$${p.price.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.pink),
            ),
            const SizedBox(height: 12),

            if (p.lastName.isNotEmpty ||
                p.email.isNotEmpty ||
                p.phone.isNotEmpty ||
                p.address.isNotEmpty) ...[
              const Divider(height: 32),
              const Text(
                "Información del cliente",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              infoRow(Icons.badge, "Apellido", p.lastName),
              infoRow(Icons.email, "Email", p.email),
              infoRow(Icons.phone, "Teléfono", p.phone),
              infoRow(Icons.location_on, "Dirección", p.address),
              const SizedBox(height: 12),
            ],

            if (showForAdmin || showForClient)
              Row(
                children: [
                  Icon(Icons.inventory_2, size: 18, color: stockColor),
                  const SizedBox(width: 6),
                  Text(
                    outOfStock ? "Sin stock" : "Stock: ${p.cantidad}",
                    style: TextStyle(color: stockColor, fontWeight: FontWeight.w600),
                  ),
                ],
              ),

            const SizedBox(height: 16),

            // Selector de cantidad (solo cliente y si hay stock)
            if (!widget.isAdmin && !outOfStock)
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Text("Cantidad:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
                        ),
                        Text("$_qty", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: _qty < p.cantidad ? () => setState(() => _qty++) : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text("Máx: ${p.cantidad}", style: const TextStyle(color: Colors.grey)),
                ],
              ),

            const SizedBox(height: 20),
            const Text(
              "Descripción de ejemplo del producto. Aquí podrás colocar características, materiales, tallas o beneficios. "
              "Esta es información estática de demo para la UI.",
              style: TextStyle(fontSize: 16, height: 1.4),
            ),
          ],
        ),
      ),

      // Botón de compra solo para cliente
      bottomNavigationBar: widget.isAdmin || outOfStock
          ? null
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (_qty <= 0) return;
                  widget.onAddToCart?.call(p, _qty);
                  // ÚNICO pop, y seguro
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text("Agregar al carrito"),
              ),
            ),
    );
  }
}
