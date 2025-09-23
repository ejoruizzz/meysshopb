import 'package:flutter/material.dart';
import '../models/cart_item.dart';

class CartScreen extends StatefulWidget {
  final List<CartItem> cartItems;
  final void Function(int index) onRemoveItem;

  const CartScreen({super.key, required this.cartItems, required this.onRemoveItem});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  double get _total => widget.cartItems.fold(0, (sum, it) => sum + it.subtotal);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.cartItems.isEmpty
          ? const Center(
              child: Text("Tu carrito está vacío", style: TextStyle(fontSize: 18, color: Colors.grey)),
            )
          : ListView.builder(
              itemCount: widget.cartItems.length,
              itemBuilder: (context, index) {
                final it = widget.cartItems[index];
                return Dismissible(
                  key: ValueKey("${it.product.id ?? it.product.nombre}-$index"),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  direction: DismissDirection.startToEnd,
                  onDismissed: (_) => widget.onRemoveItem(index),
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(it.product.imagenUrl, width: 50, height: 50, fit: BoxFit.cover),
                      ),
                      title: Text(it.product.nombre),
                      subtitle: Text("Cantidad: ${it.qty} • \$${it.product.precio.toStringAsFixed(2)}"),
                      trailing: Text(
                        "\$${(it.subtotal).toStringAsFixed(2)}",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.pink),
                      ),
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: widget.cartItems.isEmpty
          ? null
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(
                        "\$${_total.toStringAsFixed(2)}",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.pink),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Compra realizada con éxito (demo)")),
                      );
                      setState(() => widget.cartItems.clear());
                    },
                    child: const Text("Finalizar compra"),
                  ),
                ],
              ),
            ),
    );
  }
}
