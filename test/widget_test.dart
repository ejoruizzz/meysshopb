import 'package:flutter_test/flutter_test.dart';

import 'package:meysshop_front1/main.dart';

void main() {
  testWidgets('Login screen shows welcome texts', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Bienvenido a Meysshop'), findsOneWidget);
    expect(find.text('Inicia sesión para continuar'), findsOneWidget);
    expect(find.text('¿Olvidaste tu contraseña?'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });
}
