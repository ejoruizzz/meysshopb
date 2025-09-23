import 'package:flutter/material.dart';

import '../models/product.dart';
import '../models/product_form_result.dart';
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
import '../services/api_client.dart';
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
  final bool ordersEnabled;

  const MainScreen({
    super.key,
    required this.user,
    required this.productsInitialSnapshot,
    required this.ordersInitialSnapshot,
    required this.productRepository,
    required this.orderRepository,
    required this.authService,
    required this.ordersEnabled,
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

  bool get _ordersEnabled => widget.ordersEnabled;

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
    if (_ordersEnabled) {
      _loadOrders();
    }
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
    if (!_ordersEnabled) return;
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

  bool _sameProduct(Product a, Product b) {
    if (a.id != null && b.id != null) {
      return a.id == b.id;
    }
    final nameA = a.nombre.trim().toLowerCase();
    final nameB = b.nombre.trim().toLowerCase();
    if (nameA != nameB) return false;
    final categoryA = a.categoria.trim().toLowerCase();
    final categoryB = b.categoria.trim().toLowerCase();
    if (categoryA.isEmpty || categoryB.isEmpty) return true;
    return categoryA == categoryB;
  }

  String _productDisplayName(Product product) {
    final name = product.nombre.trim();
    return name.isEmpty ? 'Producto' : name;
  }

  int _availableStockOf(Product product) {
    final match = _products.where((p) => _sameProduct(p, product));
    if (match.isNotEmpty) return match.first.stock;
    return product.stock;
  }

  int _qtyInCartOf(Product product) {
    final idx = _cart.indexWhere((it) => _sameProduct(it.product, product));
    return idx >= 0 ? _cart[idx].qty : 0;
  }

  void _addToCart(Product product, int qty) {
    if (isAdminEffective) return; // admin no compra

    final stock = _availableStockOf(product);
    final already = _qtyInCartOf(product);
    final maxAdd = stock - already;

    if (stock <= 0 || maxAdd <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "No hay stock disponible de ${_productDisplayName(product)}. Stock: $stock",
          ),
        ),
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

    final idx = _cart.indexWhere((it) => _sameProduct(it.product, product));
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
        content: Text("${_productDisplayName(product)} agregado (x$safeQty)"),

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

  // ---------- CRUD de productos ----------

  Future<void> _createProduct(ProductFormResult result) async {
    if (result.imageFile == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una imagen para el producto.')),
      );
      return;
    }
    try {
      final created = await widget.productRepository.createProduct(
        result.product,
        imageFile: result.imageFile,
      );
      await _loadProducts();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Producto '${created.nombre}' agregado")),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear producto: $e')),
      );
    }
  }

  Future<void> _editProduct(int index, ProductFormResult result) async {
    try {
      final updated = await widget.productRepository.updateProduct(
        result.product,
        imageFile: result.imageFile,
      );
      await _loadProducts();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Producto '${updated.nombre}' actualizado")),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar producto: $e')),
      );
    }
  }

  // ---------- Pedidos ----------

  Future<void> _updateOrderStatus(String orderId, OrderStatus newStatus) async {
    if (!_ordersEnabled) {
      _showOrdersComingSoon();
      return;
    }
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

  void _showOrdersComingSoon() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('El módulo de pedidos estará disponible próximamente.'),
      ),
    );
  }

  Widget _buildOrdersComingSoon() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_shipping_outlined,
              size: 72,
              color: theme.primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Pedidos próximamente',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Estamos trabajando en la gestión de pedidos. Muy pronto estará disponible.',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
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
          ordersEnabled: widget.ordersEnabled,
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Páginas según rol
    final Widget adminOrdersTab = !_ordersEnabled
        ? _buildOrdersComingSoon()
        : _loadingOrders
            ? const Center(child: CircularProgressIndicator())
            : AdminOrdersScreen(
                orders: _orders,
                onUpdateStatus: _updateOrderStatus,
                showAppBar: false,
              );

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
            // 1) Pedidos o mensaje temporal
            adminOrdersTab,
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
              orderHistorySubtitle: null,
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
              onOpenOrderHistory:
                  _ordersEnabled ? _openOrderHistory : _showOrdersComingSoon,
              onLogout: _logout,
              orderHistorySubtitle:
                  _ordersEnabled ? null : 'Disponible próximamente',
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
                final result = await Navigator.push<ProductFormResult?>(
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
