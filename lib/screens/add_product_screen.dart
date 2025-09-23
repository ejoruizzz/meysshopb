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
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _categoriaController = TextEditingController();
  final _precioController = TextEditingController();
  final _stockController = TextEditingController();
  final _imagenUrlController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? _selectedImageFile;
  String? _imageError;

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _categoriaController.dispose();
    _precioController.dispose();
    _stockController.dispose();
    _imagenUrlController.dispose();
    super.dispose();
  }

  bool _isValidImageUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    final uri = Uri.tryParse(trimmed);
    if (uri == null) return false;
    final scheme = uri.scheme.toLowerCase();
    return scheme == 'http' || scheme == 'https';
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
    final trimmedUrl = _imagenUrlController.text.trim();

    if (_selectedImageFile == null && trimmedUrl.isEmpty) {
      setState(() {
        _imageError =
            'Proporciona una URL de imagen o selecciona un archivo JPG o PNG.';
      });
      return;
    }

    setState(() => _imageError = null);

    final product = Product(
      nombre: _nombreController.text.trim(),
      descripcion: _descripcionController.text.trim(),
      categoria: _categoriaController.text.trim(),
      precio: double.parse(_precioController.text.trim()),
      stock: int.parse(_stockController.text.trim()),
      imagenUrl: trimmedUrl,
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
                  controller: _nombreController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: "Nombre",
                    prefixIcon: Icon(Icons.shopping_bag),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? "Ingresa el nombre" : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _descripcionController,
                  textInputAction: TextInputAction.next,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Descripción",
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.description),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? "Describe el producto"
                      : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _categoriaController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: "Categoría",
                    prefixIcon: Icon(Icons.category),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? "Indica la categoría"
                      : null,
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
                    if (p == null || p <= 0) return "Ingresa un precio válido";
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _imagenUrlController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: "URL de la imagen (opcional)",
                    prefixIcon: Icon(Icons.link),
                  ),
                  onChanged: (_) {
                    if (_selectedImageFile == null) {
                      setState(() {});
                    }
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    return _isValidImageUrl(value)
                        ? null
                        : "Ingresa una URL válida";
                  },
                ),
                const SizedBox(height: 15),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.file_upload),
                    label: const Text('Seleccionar archivo de imagen (JPG/PNG)'),
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
                if (_selectedImageFile == null &&
                    _isValidImageUrl(_imagenUrlController.text))
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _imagenUrlController.text.trim(),
                        height: 160,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 160,
                          color: Colors.grey.shade200,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
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
                  controller: _stockController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: "Stock disponible",
                    prefixIcon: Icon(Icons.format_list_numbered),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return "Campo obligatorio";
                    final q = int.tryParse(v);
                    if (q == null || q < 0) return "Ingresa una cantidad válida";
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
