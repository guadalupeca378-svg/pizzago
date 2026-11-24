import 'package:flutter_test/flutter_test.dart';
import 'package:pizzago/core/theme/app_theme.dart';

void main() {
  for (final (name, theme) in [('claro', AppTheme.light()), ('oscuro', AppTheme.dark())]) {
    test('tema $name: los títulos usan la escala tipográfica de Material 3', () {
      final appBarTitle = theme.appBarTheme.titleTextStyle;
      expect(appBarTitle?.fontSize, 22);
      expect(appBarTitle?.fontFamily, AppTheme.sans);
      expect(theme.dialogTheme.titleTextStyle?.fontSize, 24);
      expect(theme.textTheme.bodyMedium?.fontFamily, AppTheme.sans);
    });
  }
}
