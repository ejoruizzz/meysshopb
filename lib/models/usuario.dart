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

  factory Usuario.fromJson(Map<String, dynamic> json) {
    final dynamic rawId = json['id'] ?? json['userId'];
    if (rawId == null) {
      throw const FormatException('Usuario JSON sin "id"');
    }

    String _readString(dynamic value, {String fallback = ''}) {
      if (value is String) return value;
      if (value == null) return fallback;
      return value.toString();
    }

    final id = _readString(rawId);
    final nombre = _readString(json['nombre'] ?? json['name'], fallback: '');
    final email = _readString(json['email'], fallback: '');
    if (nombre.isEmpty) {
      throw const FormatException('Usuario JSON sin "nombre"');
    }
    if (email.isEmpty) {
      throw const FormatException('Usuario JSON sin "email"');
    }

    return Usuario(
      id: id,
      nombre: nombre,
      email: email,
      rol: _readString(json['rol'] ?? json['role'], fallback: 'cliente'),
      phone: (json['phone'] ?? json['telefono'] ?? json['phoneNumber']) as String?,
      avatarUrl: (json['avatarUrl'] ?? json['avatar_url'] ?? json['avatar']) as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'rol': rol,
      if (phone != null) 'phone': phone,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    };
  }

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
