import '../models/usuario.dart';

/// Contrato para leer/editar el perfil del usuario autenticado.
abstract class ProfileRepository {
  /// Devuelve el usuario autenticado actual.
  Future<Usuario> getMe();

  /// Actualiza los datos del usuario y devuelve la versión guardada.
  Future<Usuario> updateMe(Usuario u);
}
