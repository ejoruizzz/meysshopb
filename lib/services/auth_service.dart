import '../models/usuario.dart';

/// Contrato de autenticación. La UI solo depende de esta interfaz.
abstract class AuthService {
  /// Inicia sesión y devuelve el usuario autenticado.
  Future<Usuario> login({required String email, required String password});

  /// Registra un nuevo usuario y devuelve su perfil básico.
  Future<Usuario> register({
    required String nombre,
    required String email,
    required String password,
  });

  /// Cierra sesión (en dummy no hace mucho, pero mantenemos la firma).
  Future<void> logout();

  /// Para escenarios con tokens. En dummy no se usa.
  Future<String?> refreshToken();
}
