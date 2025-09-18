class Product {
  final String name;
  final double price;
  final String imageUrl;
  final int cantidad;
  final String estado;

  const Product({
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.cantidad,
    required this.estado,
  });

  Product copyWith({
    String? name,
    double? price,
    String? imageUrl,
    int? cantidad,
    String? estado,
  }) {
    return Product(
      name: name ?? this.name,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      cantidad: cantidad ?? this.cantidad,
      estado: estado ?? this.estado,
    );
  }
}