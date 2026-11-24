import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/motion.dart';
import '../widgets/auth_layout.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: brandGradient),
        child: SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutBack,
                builder: (_, t, child) => Opacity(
                  opacity: t.clamp(0.0, 1.0),
                  child: Transform.scale(scale: .7 + .3 * t, child: child),
                ),
                child: const AppLogo(size: 96, inverted: true),
              ),
              const SizedBox(height: 28),
              EntranceAnimation(
                index: 2,
                child: Text(
                  'PizzaGo',
                  style: const TextStyle(fontFamily: AppTheme.serif, fontSize: 44, color: Colors.white, height: 1),
                ),
              ),
              const SizedBox(height: 10),
              EntranceAnimation(
                index: 3,
                child: Text(
                  'Pizza artesanal a domicilio',
                  style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white.withValues(alpha: .85)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
