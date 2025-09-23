import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/order_status.dart';
import 'main_screen.dart';
import 'register_screen.dart';

// Services
import '../services/auth_service.dart';
import '../services/product_repository.dart';
import '../services/order_repository.dart';

class LoginScreen extends StatefulWidget {
  final AuthService authService;
  final ProductRepository productRepository;
  final OrderRepository orderRepository;
  final bool ordersEnabled;

  const LoginScreen({
    super.key,
    required this.authService,
    required this.productRepository,
    required this.orderRepository,
    required this.ordersEnabled,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtl.dispose();
    _passCtl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final user = await widget.authService.login(
        email: _emailCtl.text.trim(),
        password: _passCtl.text,
      );

      // Carga productos para primer snapshot
      final products = await widget.productRepository.fetchProducts();

      // Sembrar pedidos demo si es cliente (para historial/analytics)
      final seedOrders = widget.ordersEnabled
          ? _seedOrdersIfNeeded(user, products)
          : <Order>[];

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MainScreen(
            user: user,
            productsInitialSnapshot: products,
            ordersInitialSnapshot: seedOrders,
            productRepository: widget.productRepository,
            orderRepository: widget.orderRepository,
            authService: widget.authService,
            ordersEnabled: widget.ordersEnabled,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openRegister() async {
    FocusScope.of(context).unfocus();
    final result = await Navigator.push<RegisterResult>(
      context,
      MaterialPageRoute(
        builder: (_) => RegisterScreen(authService: widget.authService),
      ),
    );

    if (!mounted || result == null) return;
    _emailCtl.text = result.email;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cuenta creada exitosamente. Inicia sesión con tus credenciales.'),
      ),
    );
  }

  List<Order> _seedOrdersIfNeeded(Usuario user, List<Product> products) {
    if (user.rol != "cliente") return [];
    if (products.length < 3) return [];
    final now = DateTime.now();

    return [
      Order(
        id: "A-1001",
        customerId: user.id,
        customerName: user.nombre,
        customerEmail: user.email,
        createdAt: now.subtract(const Duration(minutes: 40)),
        status: OrderStatus.pending,
        items: [
          OrderItem(productSnapshot: products[0], qty: 1),
          OrderItem(productSnapshot: products[1], qty: 2),
        ],
        notes: "Entregar por la tarde.",
      ),
      Order(
        id: "A-1000",
        customerId: user.id,
        customerName: user.nombre,
        customerEmail: user.email,
        createdAt: now.subtract(const Duration(hours: 6)),
        status: OrderStatus.preparing,
        items: [OrderItem(productSnapshot: products[2], qty: 1)],
      ),
      Order(
        id: "A-0999",
        customerId: user.id,
        customerName: user.nombre,
        customerEmail: user.email,
        createdAt: now.subtract(const Duration(days: 1, hours: 3)),
        status: OrderStatus.shipped,
        items: [
          OrderItem(productSnapshot: products[1], qty: 1),
          OrderItem(productSnapshot: products[2], qty: 3),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Icon(Icons.store_mall_directory, size: 72, color: Colors.pink),
                  const SizedBox(height: 12),
                  Text("Bienvenido a Meysshop", style: theme.textTheme.headlineLarge),
                  const SizedBox(height: 8),
                  const Text("Inicia sesión para continuar"),
                  const SizedBox(height: 24),

                  TextFormField(
                    controller: _emailCtl,
                    decoration: const InputDecoration(
                      labelText: "Email",
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return "Ingresa tu email";
                      if (!v.contains("@")) return "Email inválido";
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _passCtl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: "Contraseña",
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Ingresa tu contraseña";
                      if (v.length < 6) return "Mínimo 6 caracteres";
                      return null;
                    },
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Recuperación de contraseña (demo)")),
                        );
                      },
                      child: const Text("¿Olvidaste tu contraseña?"),
                    ),
                  ),

                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _login,
                      child: _loading
                          ? const SizedBox(
                              height: 22, width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text("Iniciar sesión"),
                    ),
                  ),

                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('¿No tienes cuenta?'),
                      TextButton(
                        onPressed: _loading ? null : _openRegister,
                        child: const Text('Crear cuenta'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),
                  Card(
                    color: Colors.grey[50],
                    child: const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          Text("Demo:", style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 6),
                          Text("Admin → admin@example.com / admin123"),
                          Text("Cliente → cliente@example.com / cliente123"),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
