import 'package:flutter/material.dart';
import '../models/product.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _categoriaController = TextEditingController();
  final _precioController = TextEditingController();
  final _imagenController = TextEditingController();
  final _stockController = TextEditingController();

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _categoriaController.dispose();
    _precioController.dispose();
    _imagenController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final product = Product(
      nombre: _nombreController.text.trim(),
      descripcion: _descripcionController.text.trim(),
      categoria: _categoriaController.text.trim(),
      precio: double.parse(_precioController.text.trim()),
      imagenUrl: _imagenController.text.trim(),
      stock: int.parse(_stockController.text.trim()),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${product.nombre} agregado (demo)")),
    );
    Navigator.pop(context, product); // devolvemos el producto creado
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Agregar Producto")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nombreController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: "Nombre",
                    prefixIcon: Icon(Icons.shopping_bag),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? "Campo obligatorio" : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _categoriaController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: "Categoría",
                    prefixIcon: Icon(Icons.category),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? "Campo obligatorio" : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _precioController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: "Precio",
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return "Campo obligatorio";
                    final p = double.tryParse(v);
                    if (p == null || p <= 0) return "Precio inválido";
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _stockController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: "Stock",
                    prefixIcon: Icon(Icons.inventory_2),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return "Campo obligatorio";
                    final q = int.tryParse(v);
                    if (q == null || q < 0) return "Stock inválido";
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _imagenController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: "URL de la imagen",
                    prefixIcon: Icon(Icons.image),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? "Campo obligatorio" : null,
                  onChanged: (_) => setState(() {}),
                ),
                if (_imagenController.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _imagenController.text,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => const Text("No se pudo cargar la imagen"),
                      ),
                    ),
                  ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _descripcionController,
                  textInputAction: TextInputAction.newline,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: "Descripción",
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.description),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? "Campo obligatorio" : null,
                ),
                const SizedBox(height: 30),
                ElevatedButton(onPressed: _submit, child: const Text("Agregar Producto")),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
