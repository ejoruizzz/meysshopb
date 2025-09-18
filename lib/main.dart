import 'package:flutter/material.dart';
import 'models/product.dart';
import 'models/usuario.dart';
import 'screens/login_screen.dart';

// Services (Dummy hoy; luego cambias a Api*)
import 'services/auth_service_dummy.dart';
import 'services/product_repo_dummy.dart';
import 'services/order_repo_dummy.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ Usuarios demo con IDs estables
    final dummyAdmin = Usuario(
      id: "u_admin",
      nombre: "Admin User",
      email: "admin@example.com",
      rol: "admin",
      phone: "+504 9999-9999",
    );

    final dummyClient = Usuario(
      id: "u_client",
      nombre: "Cliente User",
      email: "cliente@example.com",
      rol: "cliente",
    );

    // Productos dummy
    final dummyProducts = <Product>[
      const Product(
        name: "Zapatos deportivos",
        price: 59.99,
        imageUrl: "https://picsum.photos/seed/zapatos/600/400",
        cantidad: 10,
        estado: "Activo",
      ),
      const Product(
        name: "Camiseta básica",
        price: 19.99,
        imageUrl: "https://picsum.photos/seed/camiseta/600/400",
        cantidad: 20,
        estado: "Activo",
      ),
      const Product(
        name: "Pantalón de mezclilla",
        price: 39.99,
        imageUrl: "https://picsum.photos/seed/pantalon/600/400",
        cantidad: 15,
        estado: "Activo",
      ),
    ];

    // Services Dummy (hoy)
    final authService = DummyAuthService(admin: dummyAdmin, client: dummyClient);
    final productRepo = DummyProductRepository(dummyProducts);

    // Pedidos dummy (cárgalos en MainScreen con su seeding actual,
    // o si prefieres, puedes crear aquí una lista y pasarla al DummyOrderRepository)
    final orderRepo = DummyOrderRepository([]); // inicia vacío; MainScreen puede simular/crear

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tienda Flutter',
      theme: ThemeData(
        primaryColor: Colors.pink,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.pink,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pink,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.pink, width: 2),
          ),
          labelStyle: const TextStyle(color: Colors.grey),
        ),
      ),
      // Login recibe services y los pasa al resto
      home: LoginScreen(
        authService: authService,          // ← este era el que faltaba
        productRepository: productRepo,
        orderRepository: orderRepo,
),

    );
  }
}
