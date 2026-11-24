import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pizzago/core/widgets/motion.dart';

void main() {
  testWidgets('la palomita se dibuja después de la pausa inicial', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: AnimatedCheck(size: 52, color: Colors.green, checkColor: Colors.white),
        ),
      ),
    );
    final painter = tester.renderObject(
      find.descendant(of: find.byType(AnimatedCheck), matching: find.byType(CustomPaint)),
    );
    // Durante la pausa todavía no hay nada.
    expect(painter, isNot(paints..circle()));

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(
      painter,
      paints
        ..circle()
        ..path(),
    );
  });

  testWidgets('EntranceAnimation termina visible y en su lugar', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: EntranceAnimation(index: 3, child: Text('hola')),
      ),
    );
    await tester.pumpAndSettle();
    final opacity = tester.widget<Opacity>(find.byType(Opacity));
    expect(opacity.opacity, 1);
  });
}
