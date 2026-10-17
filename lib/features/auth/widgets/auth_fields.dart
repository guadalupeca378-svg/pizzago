import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../auth_controller.dart';

class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.autofillHints,
  });

  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String>? validator;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: widget.controller,
    obscureText: _obscure,
    validator: widget.validator,
    textInputAction: widget.textInputAction,
    onFieldSubmitted: widget.onSubmitted,
    autofillHints: widget.autofillHints,
    decoration: InputDecoration(
      labelText: widget.label,
      prefixIcon: const Icon(Symbols.lock_rounded),
      suffixIcon: IconButton(
        tooltip: _obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
        onPressed: () => setState(() => _obscure = !_obscure),
        icon: Icon(_obscure ? Symbols.visibility_rounded : Symbols.visibility_off_rounded),
      ),
    ),
  );
}

class SubmitButton extends StatelessWidget {
  const SubmitButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final busy = context.select<AuthController, bool>((a) => a.isBusy);
    return FilledButton(
      onPressed: busy ? null : onPressed,
      child: busy
          ? const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 3))
          : Text(label),
    );
  }
}

void showAuthError(BuildContext context, String? message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message ?? 'Ocurrió un error, intenta de nuevo.'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
}

/// "¿No tienes cuenta? Regístrate" / "¿Ya tienes cuenta? Inicia sesión".
class AuthSwitchLink extends StatelessWidget {
  const AuthSwitchLink({super.key, required this.question, required this.action, required this.route});

  final String question;
  final String action;
  final String route;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text(question),
      TextButton(onPressed: () => context.go(route), child: Text(action)),
    ],
  );
}
