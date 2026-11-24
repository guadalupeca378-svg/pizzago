import 'package:flutter/widgets.dart';

/// Validadores para `TextFormField`. Devuelven `null` cuando el valor es válido.
abstract final class Validators {
  static final _email = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');

  static String? required(String? value, [String field = 'Este campo']) =>
      (value == null || value.trim().isEmpty) ? '$field es obligatorio' : null;

  static String? name(String? value) {
    final error = required(value, 'El nombre');
    if (error != null) return error;
    return value!.trim().length < 3 ? 'Escribe tu nombre completo' : null;
  }

  static String? email(String? value) {
    final error = required(value, 'El correo');
    if (error != null) return error;
    return _email.hasMatch(value!.trim()) ? null : 'Correo no válido';
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'La contraseña es obligatoria';
    return value.length < 6 ? 'Mínimo 6 caracteres' : null;
  }

  static String? phone(String? value) {
    final error = required(value, 'El teléfono');
    if (error != null) return error;
    return RegExp(r'^\d{10}$').hasMatch(value!.trim()) ? null : 'Debe tener 10 dígitos';
  }

  /// Vuelve opcional a otro validador: vacío (o solo espacios) es válido;
  /// si se escribió algo, debe cumplir [validator].
  static FormFieldValidator<String> optional(FormFieldValidator<String> validator) =>
      (value) => (value == null || value.trim().isEmpty) ? null : validator(value);

  static String? address(String? value) {
    final error = required(value, 'La dirección');
    if (error != null) return error;
    return value!.trim().length < 10 ? 'Agrega calle, número y colonia' : null;
  }
}
