import 'package:flutter/material.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';
import 'edit_product_screen.dart';

class ProductListScreen extends StatefulWidget {
  final List<Product> products;
  final bool isAdmin;
  final void Function(Product, int qty) onAddToCart;
  final void Function(int index, Product updated) onEditProduct;

  const ProductListScreen({
    super.key,
    required this.products,
    required this.isAdmin,
    required this.onAddToCart,
    required this.onEditProduct,
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  String _query = "";

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final filtered = widget.products.where((p) {
      if (query.isEmpty) return true;
      final searchTargets = <String>{
        p.nombre,
        p.categoria,
        p.descripcion,
      }..removeWhere((value) => value.trim().isEmpty);
      return searchTargets.any((value) => value.toLowerCase().contains(query));
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: "Buscar producto...",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 15),
          Expanded(
            child: GridView.builder(
              itemCount: filtered.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemBuilder: (context, index) {
                final product = filtered[index];
                final originalIndex = widget.products.indexOf(product);

                final bool showInventoryForThisCard =
                    widget.isAdmin || (!widget.isAdmin && product.stock < 5);

                return ProductCard(
                  product: product,
                  isAdmin: widget.isAdmin,
                  showInventory: showInventoryForThisCard,
                  enableBuy: !widget.isAdmin, // admin no compra
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailScreen(
                          product: product,
                          isAdmin: widget.isAdmin,
                          // Importante: NO hacemos pop aquí. Solo agregamos.
                          onAddToCart: widget.isAdmin ? null : widget.onAddToCart,
                        ),
                      ),
                    );
                  },
                  // Quick add (x1) desde tarjeta para cliente
                  onAddToCart: widget.isAdmin ? null : () => widget.onAddToCart(product, 1),
                  onEdit: widget.isAdmin
                      ? () async {
                          final updated = await Navigator.push<Product?>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditProductScreen(product: product),
                            ),
                          );
                          if (updated != null) {
                            widget.onEditProduct(originalIndex, updated);
                            setState(() {});
                          }
                        }
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
