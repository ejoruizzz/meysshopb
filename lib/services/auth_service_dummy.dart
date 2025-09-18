import 'dart:async';
import '../models/usuario.dart';
import 'auth_service.dart';

/// Implementación en memoria para DEMO.
/// Valida contra dos usuarios y contraseñas fijas:
/// - admin@example.com / admin123
/// - cliente@example.com / cliente123
class DummyAuthService implements AuthService {
  final Usuario admin;
  final Usuario client;

  DummyAuthService({required this.admin, required this.client});

  @override
  Future<Usuario> login({required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 250)); // micro feedback

    if (email.toLowerCase() == admin.email.toLowerCase() && password == 'admin123') {
      return admin;
    }
    if (email.toLowerCase() == client.email.toLowerCase() && password == 'cliente123') {
      return client;
    }

    throw Exception('Credenciales inválidas');
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
