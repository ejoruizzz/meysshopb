import '../models/usuario.dart';
import 'api_client.dart';
import 'profile_repository.dart';

class ApiProfileRepository implements ProfileRepository {
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
    final data = await _client.put(_mePath, body: u.toJson());
    if (data is Map<String, dynamic>) {
      return Usuario.fromJson(data);
    }
    throw const FormatException('Respuesta inesperada al actualizar el perfil');
  }
}