import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/product.dart';
import '../models/product_form_result.dart';

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
  final _cantidadController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? _selectedImageFile;
  String? _imageError;

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _cantidadController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    setState(() => _imageError = null);
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) {
        return;
      }

      final lowerName = picked.name.toLowerCase();
      const allowedExtensions = ['.jpg', '.jpeg', '.png'];
      final hasAllowedExtension =
          allowedExtensions.any((ext) => lowerName.endsWith(ext));
      if (!hasAllowedExtension) {
        setState(() {
          _imageError = 'Formato no permitido. Usa JPG o PNG.';
          _selectedImageFile = null;
        });
        return;
      }

      final file = File(picked.path);
      final bytes = await file.length();
      const maxBytes = 5 * 1024 * 1024; // 5MB
      if (bytes > maxBytes) {
        setState(() {
          _imageError = 'La imagen supera los 5MB permitidos.';
          _selectedImageFile = null;
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _selectedImageFile = file;
        _imageError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _imageError = 'No se pudo seleccionar la imagen.');
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImageFile == null) {
      setState(() {
        _imageError = 'Selecciona una imagen en formato JPG o PNG.';
      });
      return;
    }

    final product = Product(
      name: _nameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      price: double.parse(_priceController.text.trim()),
      imageUrl: '',
      cantidad: int.parse(_cantidadController.text.trim()),
      estado: "Activo",
    );

    Navigator.pop(
      context,
      ProductFormResult(product: product, imageFile: _selectedImageFile),

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
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.file_upload),
                    label: const Text('Seleccionar imagen (JPG/PNG)'),
                  ),
                ),
                if (_selectedImageFile != null)
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _selectedImageFile!,
                        height: 160,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                if (_selectedImageFile != null)
                  Text(
                    _selectedImageFile!.path.split(Platform.pathSeparator).last,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                if (_imageError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _imageError!,
                      style: const TextStyle(color: Colors.red),
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

