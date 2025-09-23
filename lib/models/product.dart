class Product {
  final String? id;
  final String nombre;
  final String descripcion;
  final double precio;
  final int stock;
  final String categoria;
  final String imagenUrl;

  const Product({
    this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.stock,
    required this.categoria,
    required this.imagenUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    double readDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    int readInt(dynamic value) {
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    String readString(dynamic value, {String fallback = ''}) {
      if (value is String) return value;
      if (value == null) return fallback;
      return value.toString();
    }

    final nombre = readString(json['nombre'] ?? json['name'], fallback: '');
    if (nombre.isEmpty) {
      throw const FormatException('Product JSON sin "nombre"');
    }

    final descripcion = readString(json['descripcion'] ?? json['description'], fallback: '');
    final categoria = readString(json['categoria'] ?? json['category'], fallback: '');

    return Product(
      id: json['id']?.toString(),
      nombre: nombre,
      descripcion: descripcion,
      precio: readDouble(json['precio'] ?? json['price']),
      stock: readInt(json['stock'] ?? json['cantidad']),
      categoria: categoria,
      imagenUrl: readString(
        json['imagenUrl'] ?? json['imagen_url'] ?? json['imageUrl'] ?? json['imagen'],
        fallback: '',
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'precio': precio,
      'stock': stock,
      'categoria': categoria,
      'imagenUrl': imagenUrl,
    };
  }

  Product copyWith({
    String? id,
    String? nombre,
    String? descripcion,
    double? precio,
    int? stock,
    String? categoria,
    String? imagenUrl,
  }) {
    return Product(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      precio: precio ?? this.precio,
      stock: stock ?? this.stock,
      categoria: categoria ?? this.categoria,
      imagenUrl: imagenUrl ?? this.imagenUrl,
    );
  }
}
