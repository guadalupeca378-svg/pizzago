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

  /// Manda el enlace para cambiar la contraseña al correo escrito.
  Future<void> _forgotPassword() async {
    final messenger = ScaffoldMessenger.of(context);
    final email = _email.text.trim();
    final invalid = Validators.email(email);
    if (invalid != null) {
      messenger.showSnackBar(const SnackBar(content: Text('Escribe tu correo para mandarte el enlace.')));
      return;
    }
    final error = await context.read<AuthController>().sendPasswordReset(email);
    messenger.showSnackBar(
      SnackBar(content: Text(error ?? 'Si la cuenta existe, te llegará un correo para cambiar tu contraseña.')),
    );
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
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: _forgotPassword, child: const Text('¿Olvidaste tu contraseña?')),
              ),
              const SizedBox(height: 8),
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
