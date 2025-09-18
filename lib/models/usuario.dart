class Usuario {
  final String id;           // estable (clave real para enlazar pedidos)
  String nombre;
  String email;
  String? phone;
  String? avatarUrl;
  final String rol;          // "admin" | "cliente"

  Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    this.phone,
    this.avatarUrl,
  });

  Usuario copyWith({
    String? id,
    String? nombre,
    String? email,
    String? phone,
    String? avatarUrl,
    String? rol,
  }) {
    return Usuario(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      rol: rol ?? this.rol,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
