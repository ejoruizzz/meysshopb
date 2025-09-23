import 'package:flutter_test/flutter_test.dart';
import 'package:meysshop_front1/models/usuario.dart';
import 'package:meysshop_front1/services/auth_service_dummy.dart';

void main() {
  group('DummyAuthService', () {
    late DummyAuthService service;

    setUp(() {
      service = DummyAuthService(
        admin: Usuario(
          id: 'admin-id',
          nombre: 'Admin',
          email: 'admin@example.com',
          rol: 'admin',
        ),
        client: Usuario(
          id: 'client-id',
          nombre: 'Cliente',
          email: 'cliente@example.com',
          rol: 'cliente',
        ),
      );
    });

    test('permite login con usuarios sembrados', () async {
      final adminUser = await service.login(
        email: 'admin@example.com',
        password: 'admin123',
      );
      expect(adminUser.rol, 'admin');

      final clientUser = await service.login(
        email: 'cliente@example.com',
        password: 'cliente123',
      );
      expect(clientUser.rol, 'cliente');
    });

    test('register agrega nuevo usuario y permite login posterior', () async {
      final nuevo = await service.register(
        nombre: '  Nuevo Cliente  ',
        email: 'nuevo@example.com ',
        password: 'secreto123',
      );

      expect(nuevo.id, isNotEmpty);
      expect(nuevo.email, 'nuevo@example.com');
      expect(nuevo.nombre, 'Nuevo Cliente');
      expect(nuevo.rol, 'cliente');

      final loginUser = await service.login(
        email: 'nuevo@example.com',
        password: 'secreto123',
      );
      expect(loginUser.email, 'nuevo@example.com');
      expect(loginUser.nombre, 'Nuevo Cliente');
    });

    test('no permite registrar un email duplicado', () async {
      await expectLater(
        service.register(
          nombre: 'Otro usuario',
          email: 'admin@example.com',
          password: 'password',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
