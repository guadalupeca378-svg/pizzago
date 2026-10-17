import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/form_fields.dart';
import '../../../core/widgets/summary_card.dart';
import '../../../data/models/pizza_order.dart';
import '../../auth/auth_controller.dart';
import '../../orders/order_controller.dart';
import '../cart_controller.dart';
import '../widgets/checkout_widgets.dart';
import '../widgets/order_line.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _address;
  late final TextEditingController _phone;
  final _notes = TextEditingController();
  PaymentMethod _payment = PaymentMethod.efectivo;
  bool _saveToProfile = true;
  bool _placed = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthController>().user;
    _address = TextEditingController(text: user?.address);
    _phone = TextEditingController(text: user?.phone);
  }

  @override
  void dispose() {
    _address.dispose();
    _phone.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthController>();
    final orders = context.read<OrderController>();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    final order = await orders.placeOrder(
      cart: context.read<CartController>(),
      address: _address.text,
      phone: _phone.text,
      paymentMethod: _payment,
      notes: _notes.text,
    );

    if (order == null) {
      messenger.showSnackBar(SnackBar(content: Text(orders.error ?? 'No se pudo enviar el pedido')));
      return;
    }
    // El pedido ya se hizo: se marca para no mostrar "No hay nada que pagar"
    // ahora que el carrito quedó vacío, y se navega de inmediato.
    if (mounted) setState(() => _placed = true);
    HapticFeedback.mediumImpact();
    router.go(AppRoutes.orderSuccess(order.id));

    // Guardar los datos en el perfil no debe frenar la confirmación.
    final user = auth.user;
    if (_saveToProfile && user != null) {
      auth.updateProfile(user.copyWith(address: order.address, phone: order.phone)).catchError((Object e) {
        debugPrint('No se guardaron los datos de entrega: $e');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();
    final placing = context.select<OrderController, bool>((o) => o.isPlacing);

    if (cart.isEmpty && !placing && !_placed) {
      return Scaffold(
        appBar: AppBar(title: const Text('Confirmar pedido')),
        body: EmptyState(
          icon: Symbols.receipt_long_rounded,
          title: 'No hay nada que pagar',
          action: FilledButton.tonal(onPressed: () => context.go(AppRoutes.home), child: const Text('Ir al menú')),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar pedido')),
      body: Form(
        key: _formKey,
        child: ResponsiveCenter(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            children: [
              const CheckoutStep(number: 1, title: '¿A dónde lo llevamos?'),
              AddressField(controller: _address, label: 'Dirección de entrega'),
              const SizedBox(height: 12),
              PhoneField(controller: _phone),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _saveToProfile,
                onChanged: (v) => setState(() => _saveToProfile = v ?? false),
                title: const Text('Recordar estos datos'),
              ),
              const CheckoutStep(number: 2, title: '¿Cómo vas a pagar?'),
              Row(
                children: [
                  for (final method in PaymentMethod.values) ...[
                    if (method != PaymentMethod.values.first) const SizedBox(width: 12),
                    Expanded(
                      child: PaymentOption(
                        method: method,
                        selected: _payment == method,
                        onTap: () => setState(() => _payment = method),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notes,
                maxLength: 140,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Notas para el repartidor (opcional)',
                  prefixIcon: Icon(Symbols.sticky_note_2_rounded),
                ),
              ),
              const CheckoutStep(number: 3, title: 'Revisa tu pedido'),
              SummaryCard(
                subtotal: cart.subtotal,
                discount: cart.discount,
                delivery: cart.delivery,
                total: cart.total,
                couponCode: cart.coupon?.code,
                header: Column(children: [for (final item in cart.items) OrderLine(item: item)]),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        child: FilledButton(
          onPressed: placing ? null : _placeOrder,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: placing
                ? const SizedBox.square(
                    key: ValueKey('loading'),
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                : Text('Pedir ahora · ${Fmt.money(cart.total)}', key: const ValueKey('label')),
          ),
        ),
      ),
    );
  }
}
