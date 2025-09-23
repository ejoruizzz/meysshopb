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
