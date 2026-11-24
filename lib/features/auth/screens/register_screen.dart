import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/form_fields.dart';
import '../auth_controller.dart';
import '../widgets/auth_fields.dart';
import '../widgets/auth_layout.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    for (final c in [_name, _email, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthController>();
    final ok = await auth.register(name: _name.text, email: _email.text, password: _password.text);
    if (!ok && mounted) showAuthError(context, auth.error);
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Crea tu cuenta',
      subtitle: 'Te toma menos de un minuto.',
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _name,
                validator: Validators.name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                decoration: const InputDecoration(
                  labelText: 'Nombre completo',
                  prefixIcon: Icon(Symbols.person_rounded),
                ),
              ),
              const SizedBox(height: 16),
              EmailField(controller: _email),
              const SizedBox(height: 16),
              PasswordField(
                controller: _password,
                label: 'Contraseña',
                validator: Validators.password,
                autofillHints: const [AutofillHints.newPassword],
              ),
              const SizedBox(height: 16),
              PasswordField(
                controller: _confirm,
                label: 'Confirmar contraseña',
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                validator: (v) => v != _password.text ? 'Las contraseñas no coinciden' : null,
              ),
              const SizedBox(height: 24),
              SubmitButton(label: 'Crear cuenta', onPressed: _submit),
              const SizedBox(height: 16),
              const AuthSwitchLink(question: '¿Ya tienes cuenta?', action: 'Inicia sesión', route: AppRoutes.login),
            ],
          ),
        ),
      ),
    );
  }
}
