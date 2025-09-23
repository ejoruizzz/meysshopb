import 'package:flutter/material.dart';

import 'models/product.dart';
import 'models/usuario.dart';
import 'screens/login_screen.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/auth_service_api.dart';
import 'services/auth_service_dummy.dart';
import 'services/order_repo_dummy.dart';
import 'services/order_repository.dart';
import 'services/product_repo_api.dart';
import 'services/product_repo_dummy.dart';
import 'services/product_repository.dart';

const bool kUseMockServices = bool.fromEnvironment(
  'USE_MOCK_SERVICES',
  defaultValue: false,
);

const bool kOrdersFeatureEnabled = bool.fromEnvironment(
  'ORDERS_FEATURE_ENABLED',
  defaultValue: kUseMockServices,
);

const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:3001',
);

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  late final ApiClient _apiClient = ApiClient(baseUrl: kApiBaseUrl);

  @override
  Widget build(BuildContext context) {
    late final AuthService authService;
    late final ProductRepository productRepo;
    late final OrderRepository orderRepo;

    if (kUseMockServices) {
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

      authService = DummyAuthService(admin: dummyAdmin, client: dummyClient);
      productRepo = DummyProductRepository(dummyProducts);
      orderRepo = DummyOrderRepository([]);
    } else {
      authService = ApiAuthService(_apiClient);
      productRepo = ApiProductRepository(_apiClient);
      orderRepo = DummyOrderRepository([]);
    }

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
        authService: authService,
        productRepository: productRepo,
        orderRepository: orderRepo,
        ordersEnabled: kOrdersFeatureEnabled,
      ),
    );
  }
}
