import 'dart:async';

import '../models/usuario.dart';
import 'auth_service.dart';

/// Implementación en memoria para DEMO.
/// Valida contra usuarios precargados y los que se registren en la sesión actual.
class DummyAuthService implements AuthService {
  DummyAuthService({required Usuario admin, required Usuario client}) {
    _registerSeedUser(admin, 'admin123');
    _registerSeedUser(client, 'cliente123');
  }

  final Map<String, _DummyAccount> _accounts = {};
  final Set<String> _usedIds = <String>{};
  int _idSequence = 0;

  @override
  Future<Usuario> login({required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 250));

    final account = _accounts[_normalizeEmail(email)];
    if (account == null || account.password != password) {
      throw Exception('Credenciales inválidas');
    }
    return account.usuario;
  }

  @override
  Future<Usuario> register({
    required String nombre,
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final normalizedEmail = _normalizeEmail(email);
    if (_accounts.containsKey(normalizedEmail)) {
      throw Exception('Email ya registrado');
    }

    final usuario = Usuario(
      id: _generateId(),
      nombre: nombre.trim(),
      email: email.trim(),
      rol: 'cliente',
    );

    _accounts[normalizedEmail] =
        _DummyAccount(usuario: usuario, password: password);
    return usuario;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 120));
  }

  @override
  Future<String?> refreshToken() async {
    // No aplica en dummy.
    return null;
  }

  void _registerSeedUser(Usuario usuario, String password) {
    final key = _normalizeEmail(usuario.email);
    _accounts[key] = _DummyAccount(usuario: usuario, password: password);
    _usedIds.add(usuario.id);
  }

  String _normalizeEmail(String email) => email.trim().toLowerCase();

  String _generateId() {
    while (true) {
      _idSequence++;
      final candidate = 'dummy-${_idSequence.toString().padLeft(4, '0')}';
      if (_usedIds.add(candidate)) {
        return candidate;
      }
    }
  }
}

class _DummyAccount {
  const _DummyAccount({required this.usuario, required this.password});

  final Usuario usuario;
  final String password;
}
