import 'dart:async';
import '../models/usuario.dart';
import 'profile_repository.dart';

/// Repositorio de perfil en memoria (dummy).
/// Guarda y devuelve el usuario actual sin backend.
class DummyProfileRepository implements ProfileRepository {
  Usuario _current;

  /// Pasa el usuario autenticado inicial (después del login).
  DummyProfileRepository({required Usuario initialUser}) : _current = initialUser;

  @override
  Future<Usuario> getMe() async {
    await Future.delayed(const Duration(milliseconds: 120)); // micro delay demo
    return _current;
  }

  @override
  Future<Usuario> updateMe(Usuario u) async {
    // Aquí podrías validar reglas (email único, etc.) en un futuro.
    await Future.delayed(const Duration(milliseconds: 150));
    _current = u;
    return _current;
  }
}
