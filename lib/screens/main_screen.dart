import 'package:flutter/material.dart';

import '../models/product.dart';
import '../models/usuario.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/order_status.dart';

// Screens
import 'product_list_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import 'add_product_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_analytics_screen.dart';
import 'edit_profile_screen.dart';
import 'order_history_screen.dart';
import 'login_screen.dart';

// Services
import '../services/auth_service.dart';
import '../services/product_repository.dart';
import '../services/order_repository.dart';

class MainScreen extends StatefulWidget {
  final Usuario user;

  // Snapshots iniciales (para evitar pantallas vacías en el primer frame)
  final List<Product> productsInitialSnapshot;
  final List<Order> ordersInitialSnapshot;

  final ProductRepository productRepository;
  final OrderRepository orderRepository;
  final AuthService authService;

  const MainScreen({
    super.key,
    required this.user,
    required this.productsInitialSnapshot,
    required this.ordersInitialSnapshot,
    required this.productRepository,
    required this.orderRepository,
    required this.authService,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  late Usuario _currentUser;
  late List<Product> _products;
  late List<Order> _orders;

  final List<CartItem> _cart = [];

  bool _loadingProducts = false;
  bool _loadingOrders = false;

  /// Si es admin real y NO está en "ver como cliente", se considera admin efectivo.
  bool _viewAsClient = false;
  bool get isActualAdmin => _currentUser.rol == "admin";
  bool get isAdminEffective => isActualAdmin && !_viewAsClient;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _products = List<Product>.from(widget.productsInitialSnapshot);
    _orders = List<Order>.from(widget.ordersInitialSnapshot);
    _loadProducts();
    _loadOrders();
  }

  Future<void> _loadProducts() async {
    setState(() => _loadingProducts = true);
    try {
      final list = await widget.productRepository.fetchProducts();
      if (!mounted) return;
      setState(() => _products = list);
    } finally {
      if (mounted) setState(() => _loadingProducts = false);
    }
  }

  Future<void> _loadOrders() async {
    setState(() => _loadingOrders = true);
    try {
      final list = await widget.orderRepository.fetchOrders();
      if (!mounted) return;
      setState(() => _orders = list);
    } finally {
      if (mounted) setState(() => _loadingOrders = false);
    }
  }

  // ---------- Helpers de stock / carrito ----------

  int _availableStockOf(Product product) {
    final match = _products.where((p) => p.name == product.name);
    if (match.isNotEmpty) return match.first.cantidad;
    return product.cantidad;
  }

  int _qtyInCartOf(Product product) {
    final idx = _cart.indexWhere((it) => it.product.name == product.name);
    return idx >= 0 ? _cart[idx].qty : 0;
    }

  void _addToCart(Product product, int qty) {
    if (isAdminEffective) return; // admin no compra

    final stock = _availableStockOf(product);
    final already = _qtyInCartOf(product);
    final maxAdd = stock - already;

    if (stock <= 0 || maxAdd <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No hay stock disponible de ${product.name}. Stock: $stock")),
      );
      return;
    }

    final safeQty = qty > maxAdd ? maxAdd : qty;
    if (safeQty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No puedes agregar más. Stock disponible: $maxAdd")),
      );
      return;
    }

    final idx = _cart.indexWhere((it) => it.product.name == product.name);
    setState(() {
      if (idx >= 0) {
        _cart[idx] = _cart[idx].copyWith(qty: _cart[idx].qty + safeQty);
      } else {
        _cart.add(CartItem(product: product, qty: safeQty));
      }
    });

    // Feedback + acción para ver el carrito
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${product.name} agregado (x$safeQty)"),
        action: SnackBarAction(
          label: "Ver carrito",
          onPressed: () {
            // Cambia a la pestaña de carrito si es cliente
            if (!isAdminEffective) {
              setState(() => _selectedIndex = 1); // cliente: idx 1 = carrito
            }
          },
        ),
      ),
    );
  }

  void _removeFromCart(int index) {
    if (isAdminEffective) return;
    setState(() => _cart.removeAt(index));
  }

  // ---------- CRUD de productos (dummy); si quisieras persistir, llama a repo y recarga ----------

  Future<void> _createProduct(Product p) async {
    // En dummy sólo agregamos a la lista local.
    // Para persistir: await widget.productRepository.createProduct(p); await _loadProducts();
    setState(() => _products.add(p));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Producto '${p.name}' agregado")),
    );
  }

  Future<void> _editProduct(int index, Product updated) async {
    // Para persistir: await widget.productRepository.updateProduct(updated); await _loadProducts();
    setState(() => _products[index] = updated);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Producto '${updated.name}' actualizado")),
    );
  }

  // ---------- Pedidos ----------

  Future<void> _updateOrderStatus(String orderId, OrderStatus newStatus) async {
    await widget.orderRepository.updateStatus(orderId, newStatus);
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx == -1) return;
    setState(() {
      _orders[idx] = _orders[idx].copyWith(status: newStatus);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Pedido #$orderId → ${newStatus.label}")),
    );
  }

  void _reorderItems(List<OrderItem> items) {
    for (final it in items) {
      _addToCart(it.productSnapshot, it.qty);
    }
  }

  // ---------- Perfil ----------

  void _openEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          user: _currentUser,
          onSave: (updated) {
            setState(() {
              _currentUser = updated;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Perfil actualizado")),
            );
          },
        ),
      ),
    );
  }

  void _openOrderHistory() {
    if (isAdminEffective) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderHistoryScreen(
          customerId: _currentUser.id,
          allOrders: _orders,
          onReorder: _reorderItems,
        ),
      ),
    );
  }

  // ---------- Logout ----------

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Cerrar sesión"),
        content: const Text("¿Seguro que deseas cerrar sesión?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Salir"),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    // Limpia estado local mínimo
    setState(() {
      _cart.clear();
      _viewAsClient = false;
    });

    // Service logout (en dummy no hace mucho, pero queda homogéneo)
    await widget.authService.logout();

    if (!mounted) return;

    // Volver al login reusando los mismos services
    Navigator.of(context).pushAndRemoveUntil(
  MaterialPageRoute(
    builder: (_) => LoginScreen(
      authService: widget.authService,
      productRepository: widget.productRepository,
      orderRepository: widget.orderRepository,
    ),
  ),
  (route) => false,
);

  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    // Páginas según rol
    final List<Widget> screens = isAdminEffective
        ? [
            // 0) Productos (admin: sin carrito)
            _loadingProducts
                ? const Center(child: CircularProgressIndicator())
                : ProductListScreen(
                    products: _products,
                    isAdmin: true,
                    onAddToCart: (_, __) {}, // admin no compra
                    onEditProduct: _editProduct,
                  ),
            // 1) Pedidos
            _loadingOrders
                ? const Center(child: CircularProgressIndicator())
                : AdminOrdersScreen(
                    orders: _orders,
                    onUpdateStatus: _updateOrderStatus,
                    showAppBar: false,
                  ),
            // 2) Estadísticas
            AdminAnalyticsScreen(orders: _orders),
            // 3) Perfil
            ProfileScreen(
              user: _currentUser,
              isActualAdmin: true,
              viewAsClient: _viewAsClient,
              onToggleViewAsClient: (val) {
                setState(() {
                  _viewAsClient = val;
                  _selectedIndex = 0;
                });
              },
              onEditProfile: _openEditProfile,
              onOpenOrderHistory: null, // admin no tiene historial de compras
              onLogout: _logout,
            ),
          ]
        : [
            // CLIENTE
            _loadingProducts
                ? const Center(child: CircularProgressIndicator())
                : ProductListScreen(
                    products: _products,
                    isAdmin: false,
                    onAddToCart: _addToCart,
                    onEditProduct: _editProduct, // ignorado para cliente
                  ),
            CartScreen(
              cartItems: _cart,
              onRemoveItem: _removeFromCart,
            ),
            ProfileScreen(
              user: _currentUser,
              isActualAdmin: isActualAdmin,
              viewAsClient: _viewAsClient,
              onToggleViewAsClient: isActualAdmin
                  ? (val) {
                      setState(() {
                        _viewAsClient = val;
                        _selectedIndex = 0;
                      });
                    }
                  : null,
              onEditProfile: _openEditProfile,
              onOpenOrderHistory: _openOrderHistory,
              onLogout: _logout,
            ),
          ];

    final List<BottomNavigationBarItem> items = isAdminEffective
        ? const [
            BottomNavigationBarItem(icon: Icon(Icons.store), label: "Productos"),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: "Pedidos"),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Estadísticas"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
          ]
        : const [
            BottomNavigationBarItem(icon: Icon(Icons.store), label: "Productos"),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "Carrito"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
          ];

    if (_selectedIndex >= screens.length) {
      _selectedIndex = 0;
    }

    final title = isAdminEffective
        ? (["Productos", "Pedidos", "Estadísticas", "Perfil"][_selectedIndex])
        : (["Productos", "Carrito", "Perfil"][_selectedIndex]);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) {
          if (i >= screens.length) return;
          setState(() => _selectedIndex = i);
        },
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.grey,
        items: items,
      ),
      floatingActionButton: isAdminEffective && _selectedIndex == 0
          ? FloatingActionButton(
              backgroundColor: Colors.pink,
              onPressed: () async {
                final result = await Navigator.push<Product?>(
                  context,
                  MaterialPageRoute(builder: (_) => const AddProductScreen()),
                );
                if (result != null) {
                  await _createProduct(result);
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
