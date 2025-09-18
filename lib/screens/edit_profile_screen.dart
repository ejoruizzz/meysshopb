import 'package:flutter/material.dart';
import '../models/usuario.dart';

class EditProfileScreen extends StatefulWidget {
  final Usuario user;
  final ValueChanged<Usuario> onSave;

  const EditProfileScreen({super.key, required this.user, required this.onSave});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtl;
  late TextEditingController _emailCtl;
  late TextEditingController _phoneCtl;
  late TextEditingController _avatarCtl;

  @override
  void initState() {
    super.initState();
    _nameCtl = TextEditingController(text: widget.user.nombre);
    _emailCtl = TextEditingController(text: widget.user.email);
    _phoneCtl = TextEditingController(text: widget.user.phone ?? "");
    _avatarCtl = TextEditingController(text: widget.user.avatarUrl ?? "");
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _emailCtl.dispose();
    _phoneCtl.dispose();
    _avatarCtl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final updated = widget.user.copyWith(
      nombre: _nameCtl.text.trim(),
      email: _emailCtl.text.trim(),
      phone: _phoneCtl.text.trim().isEmpty ? null : _phoneCtl.text.trim(),
      avatarUrl: _avatarCtl.text.trim().isEmpty ? null : _avatarCtl.text.trim(),
    );
    widget.onSave(updated);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Editar perfil")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Center(
                child: CircleAvatar(
                  radius: 46,
                  backgroundColor: Colors.pink[100],
                  backgroundImage: (_avatarCtl.text.trim().isNotEmpty)
                      ? NetworkImage(_avatarCtl.text.trim())
                      : null,
                  child: (_avatarCtl.text.trim().isEmpty)
                      ? const Icon(Icons.person, size: 52, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _avatarCtl,
                decoration: const InputDecoration(
                  labelText: "URL de avatar (opcional)",
                  prefixIcon: Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtl,
                decoration: const InputDecoration(
                  labelText: "Nombre",
                  prefixIcon: Icon(Icons.badge),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? "El nombre es obligatorio" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailCtl,
                decoration: const InputDecoration(
                  labelText: "Email",
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return "El email es obligatorio";
                  if (!v.contains("@")) return "Email inválido";
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneCtl,
                decoration: const InputDecoration(
                  labelText: "Teléfono (opcional)",
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text("Guardar cambios"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
