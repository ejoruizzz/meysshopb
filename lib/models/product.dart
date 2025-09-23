class Product {
  final String? id;
  final String name;
  final double price;
  final String imageUrl;
  final int cantidad;
  final String estado;
  final String lastName;
  final String email;
  final String phone;
  final String address;

  const Product({
    this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.cantidad,
    required this.estado,
    this.lastName = '',
    this.email = '',
    this.phone = '',
    this.address = '',
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    double _readDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
      return 0.0;
    }

    int _readInt(dynamic value) {
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    String _readString(dynamic value, {String fallback = ''}) {
      if (value is String) return value;
      if (value == null) return fallback;
      return value.toString();
    }

    final name = _readString(json['name'] ?? json['nombre'], fallback: '');
    if (name.isEmpty) {
      throw const FormatException('Product JSON sin "name"');
    }

    return Product(
      id: json['id']?.toString(),
      name: name,
      price: _readDouble(json['price'] ?? json['precio']),
      imageUrl: _readString(
        json['imageUrl'] ?? json['imagenUrl'] ?? json['image_url'] ?? json['imagen'],
        fallback: '',
      ),
      cantidad: _readInt(json['cantidad'] ?? json['stock']),
      estado: _readString(
        json['estado'] ?? json['status'] ?? json['estadoProducto'],
        fallback: 'Activo',
      ),
      lastName: _readString(json['apellido'] ?? json['lastName'] ?? json['apellidos'], fallback: ''),
      email: _readString(json['email'] ?? json['correo'] ?? json['correoElectronico'], fallback: ''),
      phone: _readString(json['telefono'] ?? json['phone'] ?? json['celular'], fallback: ''),
      address: _readString(json['direccion'] ?? json['address'] ?? json['domicilio'], fallback: ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'nombre': name,
      'price': price,
      'imageUrl': imageUrl,
      'cantidad': cantidad,
      'estado': estado,
      'apellido': lastName,
      'email': email,
      'telefono': phone,
      'direccion': address,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    double? price,
    String? imageUrl,
    int? cantidad,
    String? estado,
    String? lastName,
    String? email,
    String? phone,
    String? address,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      cantidad: cantidad ?? this.cantidad,
      estado: estado ?? this.estado,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
    );
  }
}
