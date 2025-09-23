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
    _qty = widget.product.stock > 0 ? 1 : 0; // 0 si sin stock
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final bool showForClient = !widget.isAdmin && p.stock < 5;
    final bool showForAdmin = widget.isAdmin;
    final bool lowForAdmin = p.stock < 10;

    final Color stockColor = widget.isAdmin
        ? (lowForAdmin ? Colors.red : Colors.green)
        : Colors.red; // cliente solo lo ve si <5

    final bool outOfStock = p.stock <= 0;

    return Scaffold(
      appBar: AppBar(title: Text(p.nombre)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                p.imagenUrl,
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
              p.nombre,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            if (p.categoria.isNotEmpty) ...[
              const SizedBox(height: 8),
              Chip(
                label: Text(p.categoria),
                backgroundColor: Colors.pink.shade50,
                labelStyle: const TextStyle(color: Colors.pink, fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              "\$${p.precio.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.pink),
            ),
            const SizedBox(height: 12),
            if (showForAdmin || showForClient)
              Row(
                children: [
                  Icon(Icons.inventory_2, size: 18, color: stockColor),
                  const SizedBox(width: 6),
                  Text(
                    outOfStock ? "Sin stock" : "Stock: ${p.stock}",
                    style: TextStyle(color: stockColor, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            const SizedBox(height: 20),
            const Text(
              "Descripción",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              p.descripcion.isEmpty
                  ? "Este producto aún no tiene una descripción detallada."
                  : p.descripcion,
              style: const TextStyle(fontSize: 16, height: 1.4),
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
                          onPressed: _qty < p.stock ? () => setState(() => _qty++) : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text("Máx: ${p.stock}", style: const TextStyle(color: Colors.grey)),
                ],
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
