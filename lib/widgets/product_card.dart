import 'package:flutter/material.dart';
import '../models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final VoidCallback? onEdit;
  final bool showInventory;
  final bool isAdmin;
  final bool enableBuy;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onAddToCart,
    this.onEdit,
    this.showInventory = false,
    this.isAdmin = false,
    this.enableBuy = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool lowForAdmin = product.stock < 10;
    final Color stockColor = isAdmin
        ? (lowForAdmin ? Colors.red : Colors.green)
        : Colors.red; // cliente solo lo ve si <5

    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  product.imagenUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, _, __) => const Center(
                    child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.nombre,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (product.categoria.isNotEmpty)
                    Text(
                      product.categoria,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (product.descripcion.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      product.descripcion,
                      style: const TextStyle(fontSize: 12, color: Colors.black87),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    "\$${product.precio.toStringAsFixed(2)}",
                    style: const TextStyle(color: Colors.pink, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  if (showInventory) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.inventory_2, size: 16, color: stockColor),
                        const SizedBox(width: 6),
                        Text(
                          "Stock: ${product.stock}",
                          style: TextStyle(color: stockColor, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (enableBuy)
                  IconButton(
                    tooltip: "Agregar al carrito",
                    onPressed: onAddToCart,
                    icon: const Icon(Icons.add_shopping_cart, color: Colors.pink),
                  ),
                if (onEdit != null)
                  IconButton(
                    tooltip: "Editar producto",
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, color: Colors.grey),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
