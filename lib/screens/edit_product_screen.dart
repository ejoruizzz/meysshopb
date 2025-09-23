import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/product.dart';
import '../models/product_form_result.dart';

class EditProductScreen extends StatefulWidget {
  final Product product;
  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _priceController;
  late TextEditingController _cantidadController;
  final ImagePicker _picker = ImagePicker();

  File? _selectedImageFile;
  String? _imageError;
  late String _currentImageUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _lastNameController = TextEditingController(text: widget.product.lastName);
    _emailController = TextEditingController(text: widget.product.email);
    _phoneController = TextEditingController(text: widget.product.phone);
    _addressController = TextEditingController(text: widget.product.address);
    _priceController =
        TextEditingController(text: widget.product.price.toString());
    _cantidadController =
        TextEditingController(text: widget.product.cantidad.toString());
    _currentImageUrl = widget.product.imageUrl;
  }

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
      const maxBytes = 5 * 1024 * 1024;
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
    } catch (_) {
      if (!mounted) return;
      setState(() => _imageError = 'No se pudo seleccionar la imagen.');
    }
  }

  void _clearSelectedImage() {
    setState(() {
      _selectedImageFile = null;
      _imageError = null;
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final updated = Product(
      id: widget.product.id,
      name: _nameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      price: double.parse(_priceController.text.trim()),
      imageUrl: _currentImageUrl,
      cantidad: int.parse(_cantidadController.text.trim()),
      estado: widget.product.estado,
    );

    Navigator.pop(
      context,
      ProductFormResult(product: updated, imageFile: _selectedImageFile),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Producto')),
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
                    labelText: 'Nombre',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty
                          ? 'Campo obligatorio'
                          : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _lastNameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Apellido',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty
                          ? 'Campo obligatorio'
                          : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _emailController,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Campo obligatorio';
                    }
                    final email = value.trim();
                    if (!email.contains('@') || !email.contains('.')) {
                      return 'Correo inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _phoneController,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty
                          ? 'Campo obligatorio'
                          : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _addressController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Dirección',
                    prefixIcon: Icon(Icons.home),
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty
                          ? 'Campo obligatorio'
                          : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _priceController,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Precio',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Campo obligatorio';
                    }
                    final parsed = double.tryParse(value.trim());
                    if (parsed == null || parsed <= 0) {
                      return 'Precio inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.file_upload),
                        label: Text(
                          _selectedImageFile == null
                              ? 'Seleccionar nueva imagen'
                              : 'Cambiar imagen seleccionada',
                        ),
                      ),
                      if (_selectedImageFile != null)
                        TextButton.icon(
                          onPressed: _clearSelectedImage,
                          icon: const Icon(Icons.cancel),
                          label: const Text('Cancelar cambio'),
                        ),
                    ],
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
                  )
                else if (_currentImageUrl.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _currentImageUrl,
                        height: 160,
                        fit: BoxFit.cover,
                        errorBuilder: (context, _, __) =>
                            const Text('No se pudo cargar la imagen'),
                      ),
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Text(
                      'Sin imagen actual',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                if (_selectedImageFile != null)
                  Text(
                    _selectedImageFile!.path
                        .split(Platform.pathSeparator)
                        .last,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.grey),
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
                  textInputAction: TextInputAction.done,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Cantidad',
                    prefixIcon: Icon(Icons.format_list_numbered),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Campo obligatorio';
                    }
                    final parsed = int.tryParse(value.trim());
                    if (parsed == null || parsed < 0) {
                      return 'Cantidad inválida';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Guardar cambios'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
