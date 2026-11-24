import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/form_fields.dart';
import '../../../data/repositories/auth_repository.dart';
import '../auth_controller.dart';
import '../widgets/auth_fields.dart';
import '../widgets/auth_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthController>();
    final ok = await auth.signIn(email: _email.text.trim(), password: _password.text);
    // Si fue exitoso, el router redirige solo al menú.
    if (!ok && mounted) showAuthError(context, auth.error);
  }

  void _fillDemo() {
    _email.text = LocalAuthRepository.demoEmail;
    _password.text = LocalAuthRepository.demoPassword;
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Hola de nuevo',
      subtitle: 'Entra para pedir tu pizza favorita.',
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EmailField(controller: _email),
              const SizedBox(height: 16),
              PasswordField(
                controller: _password,
                label: 'Contraseña',
                validator: Validators.password,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                autofillHints: const [AutofillHints.password],
              ),
              const SizedBox(height: 24),
              SubmitButton(label: 'Iniciar sesión', onPressed: _submit),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _fillDemo,
                icon: const Icon(Symbols.bolt_rounded),
                label: const Text('Usar cuenta de demostración'),
              ),
              const SizedBox(height: 16),
              const AuthSwitchLink(question: '¿No tienes cuenta?', action: 'Regístrate', route: AppRoutes.register),
            ],
          ),
        ),
      ),
    );
  }
}
