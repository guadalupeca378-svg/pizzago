import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/product_image.dart';

const brandGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [AppTheme.tomato, Color(0xFF8E1F11)],
);

/// Estructura común de login y registro. En pantallas anchas: panel de
/// marca a la izquierda y formulario a la derecha; en teléfono, una columna.
class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.title, required this.subtitle, required this.child});

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final wide = MediaQuery.sizeOf(context).width >= 900;

    final form = Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!wide) ...[
                const Align(alignment: Alignment.centerLeft, child: Wordmark()),
                const SizedBox(height: 40),
              ],
              EntranceAnimation(child: Text(title, style: theme.textTheme.headlineMedium)),
              const SizedBox(height: 6),
              EntranceAnimation(
                index: 1,
                child: Text(subtitle, style: theme.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant)),
              ),
              const SizedBox(height: 32),
              EntranceAnimation(index: 2, child: child),
            ],
          ),
        ),
      ),
    );

    if (!wide) return Scaffold(body: SafeArea(child: form));

    return Scaffold(
      body: Row(
        children: [
          const Expanded(child: _BrandPanel()),
          Expanded(child: form),
        ],
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget feature(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(text, style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );

    return ColoredBox(
      color: const Color(0xFF1C1512),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(AppImages.product('margarita'), fit: BoxFit.cover),
          // Oscurece la foto para que el texto blanco se lea bien.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x99140E0B), Color(0xE6140E0B)],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Wordmark(color: Colors.white, inverted: true),
                const Spacer(),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Text(
                    'Tu pizza favorita, a un par de clics.',
                    style: theme.textTheme.displaySmall?.copyWith(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 28),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Column(
                    children: [
                      feature(Symbols.local_pizza_rounded, 'Masa artesanal y horno de piedra'),
                      feature(Symbols.schedule_rounded, 'Entrega en menos de 35 minutos'),
                      feature(Symbols.delivery_dining_rounded, r'Envío gratis desde $400'),
                    ],
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
