import 'dart:async';
import '../models/usuario.dart';
import 'auth_service.dart';

/// Implementación en memoria para DEMO.
/// Inicia con dos usuarios y permite registrar nuevos en runtime.
class DummyAuthService implements AuthService {
  DummyAuthService({required Usuario admin, required Usuario client})
      : _accounts = {
          admin.email.toLowerCase(): _DummyAccount(admin, 'admin123'),
          client.email.toLowerCase(): _DummyAccount(client, 'cliente123'),
        };

  final Map<String, _DummyAccount> _accounts;
  int _nextId = 0;

  @override
  Future<Usuario> login({required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 250)); // micro feedback

    final account = _accounts[email.trim().toLowerCase()];
    if (account != null && account.password == password) {
      return account.user;
    }

    throw Exception('Credenciales inválidas');
  }

  @override
  Future<Usuario> register({
    required String nombre,
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final key = email.trim().toLowerCase();
    if (_accounts.containsKey(key)) {
      throw Exception('Email ya registrado');
    }

    final user = Usuario(
      id: 'u_reg_${++_nextId}',
      nombre: nombre.trim(),
      email: email.trim(),
      rol: 'cliente',
    );

    _accounts[key] = _DummyAccount(user, password);
    return user;
  }

  @override
  Future<void> logout() async {
    // En dummy no hay nada que limpiar, pero mantenemos la firma para homogeneidad.
    await Future.delayed(const Duration(milliseconds: 120));
  }

  @override
  Future<String?> refreshToken() async {
    // No aplica en dummy.
    return null;
  }
}

class _DummyAccount {
  _DummyAccount(this.user, this.password);

  final Usuario user;
  final String password;
}
