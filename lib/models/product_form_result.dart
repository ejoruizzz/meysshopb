import 'dart:io';

import 'product.dart';

/// Resultado del formulario de producto que incluye los campos del
/// producto y, opcionalmente, el archivo de imagen seleccionado.
class ProductFormResult {
  ProductFormResult({
    required this.product,
    this.imageFile,
  });

  final Product product;
  final File? imageFile;
}
