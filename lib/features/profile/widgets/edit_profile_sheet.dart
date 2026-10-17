import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/validators.dart';
import '../../../core/widgets/form_fields.dart';
import '../../../data/models/app_user.dart';
import '../../auth/auth_controller.dart';

class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet({super.key, required this.user});

  final AppUser user;

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.user.name);
  late final _phone = TextEditingController(text: widget.user.phone);
  late final _address = TextEditingController(text: widget.user.address);
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<AuthController>().updateProfile(
        widget.user.copyWith(name: _name.text.trim(), phone: _phone.text.trim(), address: _address.text.trim()),
      );
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Perfil actualizado')));
    } catch (_) {
      // Si falla, el botón se vuelve a activar para intentar de nuevo.
      if (mounted) setState(() => _saving = false);
      messenger.showSnackBar(const SnackBar(content: Text('No se pudo guardar. Intenta de nuevo.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Editar perfil', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            TextFormField(
              controller: _name,
              validator: Validators.name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nombre', prefixIcon: Icon(Symbols.person_rounded)),
            ),
            const SizedBox(height: 12),
            // En el perfil son opcionales; si se escriben, deben ser válidos.
            PhoneField(controller: _phone, isRequired: false),
            const SizedBox(height: 12),
            AddressField(controller: _address, isRequired: false),
            const SizedBox(height: 24),
            FilledButton(onPressed: _saving ? null : _save, child: const Text('Guardar cambios')),
          ],
        ),
      ),
    );
  }
}
