import 'package:flutter/material.dart';
import '../models/usuario.dart';

class ProfileScreen extends StatelessWidget {
  final Usuario user;

  // Admin / vista previa
  final bool isActualAdmin;
  final bool viewAsClient;
  final ValueChanged<bool>? onToggleViewAsClient;

  // NUEVO: callbacks
  final VoidCallback? onEditProfile;
  final VoidCallback? onOpenOrderHistory; // cliente
  final VoidCallback? onLogout;
  final String? orderHistorySubtitle;

  const ProfileScreen({
    super.key,
    required this.user,
    this.isActualAdmin = false,
    this.viewAsClient = false,
    this.onToggleViewAsClient,
    this.onEditProfile,
    this.onOpenOrderHistory,
    this.onLogout,
    this.orderHistorySubtitle,
  });

  @override
  Widget build(BuildContext context) {
    final showAdminTools = isActualAdmin && !viewAsClient;
    final isClientEffective = !showAdminTools; // cliente real o admin en vista previa

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.pink[100],
              backgroundImage: (user.avatarUrl != null && user.avatarUrl!.trim().isNotEmpty)
                  ? NetworkImage(user.avatarUrl!.trim())
                  : null,
              child: (user.avatarUrl == null || user.avatarUrl!.trim().isEmpty)
                  ? const Icon(Icons.person, size: 60, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 20),
            Text(user.nombre, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(user.email, style: const TextStyle(fontSize: 16, color: Colors.grey)),
            if (user.phone != null && user.phone!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(user.phone!, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            ],
            const SizedBox(height: 24),

            // Editar perfil
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: const Icon(Icons.edit, color: Colors.pink),
                title: const Text("Editar perfil"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: onEditProfile,
              ),
            ),

            // Switch de vista previa (solo si es admin real)
            if (isActualAdmin)
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: SwitchListTile(
                  title: const Text("Vista previa como cliente"),
                  subtitle: const Text("Simula la app como cliente (sin cambiar tu rol real)"),
                  value: viewAsClient,
                  onChanged: onToggleViewAsClient,
                  activeThumbColor: Colors.pink,
                ),
              ),

            // Historial de compras (solo cliente efectivo)
            if (isClientEffective)
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: const Icon(Icons.history, color: Colors.pink),
                  title: const Text("Historial de compras"),
                  subtitle: orderHistorySubtitle != null
                      ? Text(orderHistorySubtitle!, style: const TextStyle(color: Colors.grey))
                      : null,
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: onOpenOrderHistory,
                ),
              ),

            // Cerrar sesión
            Card(
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text("Cerrar sesión"),
                onTap: onLogout,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
