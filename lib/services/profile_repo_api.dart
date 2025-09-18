import '../models/usuario.dart';
import 'api_client.dart';
import 'profile_repository.dart';

class ApiProfileRepository implements ProfileRepository {

  ApiProfileRepository(
    this._client, {
    this.mePath = '/api/profile/me',
  });

  final ApiClient _client;
  final String mePath;

  @override
  Future<Usuario> getMe() async {
    final data = await _client.get(mePath);
    if (data is! Map<String, dynamic>) {
      throw ApiException(500, 'Respuesta inválida al obtener perfil', data: data);
    }
    return _usuarioFromJson(data);

  ApiProfileRepository(this._client);

  final ApiClient _client;
  static const String _mePath = '/api/me';

  @override
  Future<Usuario> getMe() async {
    final data = await _client.get(_mePath);
    if (data is Map<String, dynamic>) {
      return Usuario.fromJson(data);
    }
    throw const FormatException('Respuesta inesperada al obtener el perfil');

  }

  @override
  Future<Usuario> updateMe(Usuario u) async {

    final data = await _client.put(mePath, body: _usuarioToJson(u));
    if (data is! Map<String, dynamic>) {
      throw ApiException(500, 'Respuesta inválida al actualizar perfil', data: data);
    }
    return _usuarioFromJson(data);
  }

  Usuario _usuarioFromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString();
    if (id == null || id.isEmpty) {
      throw ApiException(500, 'Perfil sin identificador', data: json);
    }

    String? _string(dynamic value) => value is String ? value : value?.toString();

    return Usuario(
      id: id,
      nombre: _string(json['nombre']) ?? '',
      email: _string(json['email']) ?? '',
      rol: _string(json['rol']) ?? 'cliente',
      phone: _string(json['phone'] ?? json['telefono']),
      avatarUrl: _string(json['avatarUrl'] ?? json['avatar']),
    );
  }

  Map<String, dynamic> _usuarioToJson(Usuario u) => {
        'id': u.id,
        'nombre': u.nombre,
        'email': u.email,
        'rol': u.rol,
        if (u.phone != null) 'phone': u.phone,
        if (u.avatarUrl != null) 'avatarUrl': u.avatarUrl,
      };

    final data = await _client.put(_mePath, body: u.toJson());
    if (data is Map<String, dynamic>) {
      return Usuario.fromJson(data);
    }
    throw const FormatException('Respuesta inesperada al actualizar el perfil');
  }

}