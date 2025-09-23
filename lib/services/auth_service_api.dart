import '../models/usuario.dart';
import 'api_client.dart';
import 'auth_service.dart';

/// Implementación de [AuthService] que consume el backend REST.
class ApiAuthService implements AuthService {
  ApiAuthService(this._client);

  final ApiClient _client;

  @override
  Future<Usuario> register({
    required String nombre,
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      '/api/auth/register',
      body: {
        'nombre': nombre,
        'email': email,
        'password': password,
      },
    );

    if (response is! Map<String, dynamic>) {
      throw ApiException(
        500,
        'Respuesta inválida del backend en register',
        data: response,
      );
    }

    return _usuarioFromJson(response);
  }

  @override
  Future<Usuario> login({required String email, required String password}) async {
    final response = await _client.post(
      '/api/auth/login',
      body: {
        'email': email,
        'password': password,
      },
    );

    if (response is! Map<String, dynamic>) {
      throw ApiException(500, 'Respuesta inválida del backend en login', data: response);
    }

    final access = response['access'] as String?;
    final refresh = response['refresh'] as String?;
    final usuarioJson = response['usuario'];

    if (access == null || refresh == null || usuarioJson is! Map<String, dynamic>) {
      throw ApiException(500, 'Login sin tokens o usuario válido', data: response);
    }

    _client.updateTokens(accessToken: access, refreshToken: refresh);
    return _usuarioFromJson(usuarioJson);
  }

  @override
  Future<Usuario> register({
    required String nombre,
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      '/api/auth/register',
      body: {
        'nombre': nombre,
        'email': email,
        'password': password,
      },
    );

    if (response is! Map<String, dynamic>) {
      throw ApiException(
        500,
        'Respuesta inválida del backend en register',
        data: response,
      );
    }

    final id = response['id']?.toString();
    final nombreResp = response['nombre']?.toString();
    final emailResp = response['email']?.toString();

    if (id == null || nombreResp == null || emailResp == null) {
      throw ApiException(500, 'Registro sin datos válidos', data: response);
    }

    return Usuario(
      id: id,
      nombre: nombreResp,
      email: emailResp,
      rol: 'cliente',
    );
  }

  @override
  Future<void> logout() async {
    final refresh = _client.refreshToken;
    try {
      await _client.post(
        '/api/auth/logout',
        body: refresh != null ? {'refresh': refresh} : null,
      );
    } on ApiException catch (e) {
      // Si la sesión ya no es válida, lo consideramos logout exitoso.
      if (e.statusCode != 401) rethrow;
    } finally {
      _client.clearTokens();
    }
  }

  /// Revoca todas las sesiones activas del usuario autenticado.
  Future<void> logoutAllSessions() async {
    try {
      await _client.post('/api/auth/logout-all');
    } finally {
      _client.clearTokens();
    }
  }

  @override
  Future<String?> refreshToken() => _client.refreshTokens();

  Usuario _usuarioFromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString();
    if (id == null || id.isEmpty) {
      throw ApiException(500, 'Usuario sin identificador', data: json);
    }

    String? _string(dynamic value) => value is String ? value : (value?.toString());

    return Usuario(
      id: id,
      nombre: _string(json['nombre']) ?? '',
      email: _string(json['email']) ?? '',
      rol: _string(json['rol']) ?? 'cliente',
      phone: _string(json['phone'] ?? json['telefono']),
      avatarUrl: _string(json['avatarUrl'] ?? json['avatar']),
    );
  }
}