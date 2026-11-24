import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../utils/validators.dart';

/// Campos de formulario que se repiten en varias pantallas (login, registro,
/// pago y perfil). Así el formato, el teclado y la validación son iguales en
/// todas.

class EmailField extends StatelessWidget {
  const EmailField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    validator: Validators.email,
    keyboardType: TextInputType.emailAddress,
    textInputAction: TextInputAction.next,
    autofillHints: const [AutofillHints.email],
    decoration: const InputDecoration(labelText: 'Correo electrónico', prefixIcon: Icon(Symbols.mail_rounded)),
  );
}

/// Teléfono de 10 dígitos. Con [isRequired] en `false` puede quedar vacío.
class PhoneField extends StatelessWidget {
  const PhoneField({super.key, required this.controller, this.isRequired = true});

  final TextEditingController controller;
  final bool isRequired;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    validator: isRequired ? Validators.phone : Validators.optional(Validators.phone),
    keyboardType: TextInputType.phone,
    autofillHints: const [AutofillHints.telephoneNumber],
    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
    decoration: const InputDecoration(labelText: 'Teléfono', prefixIcon: Icon(Symbols.phone_rounded)),
  );
}

/// Dirección de entrega. Con [isRequired] en `false` puede quedar vacía.
class AddressField extends StatelessWidget {
  const AddressField({super.key, required this.controller, this.isRequired = true, this.label = 'Dirección'});

  final TextEditingController controller;
  final bool isRequired;
  final String label;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    validator: isRequired ? Validators.address : Validators.optional(Validators.address),
    minLines: 1,
    maxLines: 2,
    textCapitalization: TextCapitalization.sentences,
    autofillHints: const [AutofillHints.fullStreetAddress],
    decoration: InputDecoration(
      labelText: label,
      hintText: 'Calle, número, colonia',
      prefixIcon: const Icon(Symbols.location_on_rounded),
    ),
  );
}
