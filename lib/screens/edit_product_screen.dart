import 'package:flutter/material.dart';
import '../models/product.dart';

class EditProductScreen extends StatefulWidget {
  final Product product;
  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _imageController;
  late TextEditingController _cantidadController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _priceController = TextEditingController(text: widget.product.price.toString());
    _imageController = TextEditingController(text: widget.product.imageUrl);
    _cantidadController = TextEditingController(text: widget.product.cantidad.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _imageController.dispose();
    _cantidadController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final updated = Product(
      name: _nameController.text.trim(),
      price: double.parse(_priceController.text.trim()),
      imageUrl: _imageController.text.trim(),
      cantidad: int.parse(_cantidadController.text.trim()),
      estado: widget.product.estado,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${updated.name} actualizado (demo)")),
    );
    Navigator.pop(context, updated); // devolvemos el actualizado
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Editar Producto")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: "Nombre",
                    prefixIcon: Icon(Icons.shopping_bag),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? "Campo obligatorio" : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _priceController,
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
                  controller: _imageController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: "URL de la imagen",
                    prefixIcon: Icon(Icons.image),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? "Campo obligatorio" : null,
                  onChanged: (_) => setState(() {}),
                ),
                if (_imageController.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _imageController.text,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => const Text("No se pudo cargar la imagen"),
                      ),
                    ),
                  ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _cantidadController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: "Cantidad",
                    prefixIcon: Icon(Icons.format_list_numbered),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return "Campo obligatorio";
                    final q = int.tryParse(v);
                    if (q == null || q < 1) return "Cantidad inválida";
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                ElevatedButton(onPressed: _submit, child: const Text("Guardar cambios")),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
