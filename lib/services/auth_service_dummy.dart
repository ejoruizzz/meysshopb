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

import 'dart:async';

import '../models/usuario.dart';
import 'auth_service.dart';

/// Implementación en memoria para DEMO.
/// Valida contra usuarios precargados y los que se registren en la sesión actual.
class DummyAuthService implements AuthService {
  DummyAuthService({required this.admin, required this.client}) {
    _registerSeedUser(admin, 'admin123');
    _registerSeedUser(client, 'cliente123');
  }

  final Usuario admin;
  final Usuario client;

  final Map<String, _DummyAccount> _accounts = {};
  final Set<String> _usedIds = <String>{};
  int _idSequence = 0;

  @override
  Future<Usuario> login({required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 250)); // micro feedback


    final account = _accounts[email.trim().toLowerCase()];
    if (account != null && account.password == password) {
      return account.user;
    }

    throw Exception('Credenciales inválidas');

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

    final key = email.trim().toLowerCase();

    await Future.delayed(const Duration(milliseconds: 250));

    final normalizedEmail = email.trim();
    final key = _normalizeEmail(normalizedEmail);

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

    final usuario = Usuario(
      id: _generateId(),
      nombre: nombre.trim(),
      email: normalizedEmail,
      rol: 'cliente',
    );

    _accounts[key] = _DummyAccount(usuario: usuario, password: password);
    return usuario;

  }

  @override
  Future<void> logout() async {
    
    await Future.delayed(const Duration(milliseconds: 120));
  }


  @override

  @override

  Future<String?> refreshToken() async {
    // No aplica en dummy.
    return null;
  }

}

class _DummyAccount {
  _DummyAccount(this.user, this.password);

  final Usuario user;


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
  _DummyAccount({required this.usuario, required this.password});

  final Usuario usuario;

  final String password;
}
