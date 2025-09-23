import 'package:flutter/material.dart';
import '../models/product.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageController = TextEditingController();
  final _cantidadController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _imageController.dispose();
    _cantidadController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final product = Product(
      name: _nameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      price: double.parse(_priceController.text.trim()),
      imageUrl: _imageController.text.trim(),
      cantidad: int.parse(_cantidadController.text.trim()),
      estado: "Activo",
    );

    final fullName = [product.name, product.lastName]
        .where((element) => element.isNotEmpty)
        .join(' ')
        .trim();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${fullName.isEmpty ? product.name : fullName} agregado (demo)")),
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
                  controller: _lastNameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: "Apellido",
                    prefixIcon: Icon(Icons.badge),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? "Campo obligatorio" : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return "Campo obligatorio";
                    if (!v.contains('@')) return "Email inválido";
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: "Teléfono",
                    prefixIcon: Icon(Icons.phone),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? "Campo obligatorio" : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _addressController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: "Dirección",
                    prefixIcon: Icon(Icons.location_on),
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
                ElevatedButton(onPressed: _submit, child: const Text("Agregar Producto")),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
