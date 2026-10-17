import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

/// Sistema visual de PizzaGo: superficies neutras, un solo color de acento
/// (rojo tomate) y escala tipográfica de Material 3 con Poppins.
abstract final class AppTheme {
  static const tomato = Color(0xFFD0331F);

  static const serif = 'DMSerifDisplay';
  static const sans = 'Poppins';

  // Radios del sistema.
  static const radiusSm = 12.0;
  static const radius = 16.0;
  static const radiusLg = 24.0;

  static ThemeData light() => _build(_lightScheme);
  static ThemeData dark() => _build(_darkScheme);

  static final _lightScheme = ColorScheme.fromSeed(seedColor: tomato, brightness: Brightness.light).copyWith(
    primary: tomato,
    onPrimary: Colors.white,
    primaryContainer: const Color(0xFFFFE1DA),
    onPrimaryContainer: const Color(0xFF410400),
    secondary: const Color(0xFF2F6B4A),
    onSecondary: Colors.white,
    secondaryContainer: const Color(0xFFD5EEDD),
    onSecondaryContainer: const Color(0xFF00210F),
    tertiary: const Color(0xFFA86A12),
    onTertiary: Colors.white,
    tertiaryContainer: const Color(0xFFFFE7C2),
    onTertiaryContainer: const Color(0xFF2B1700),
    surface: const Color(0xFFF7F6F3),
    onSurface: const Color(0xFF1C1B1A),
    onSurfaceVariant: const Color(0xFF6B6862),
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: const Color(0xFFF2F0EC),
    surfaceContainer: const Color(0xFFECEAE5),
    surfaceContainerHigh: const Color(0xFFE6E3DD),
    surfaceContainerHighest: const Color(0xFFDFDBD4),
    outline: const Color(0xFF9C978F),
    outlineVariant: const Color(0xFFE3DFD8),
  );

  static final _darkScheme = ColorScheme.fromSeed(seedColor: tomato, brightness: Brightness.dark).copyWith(
    primary: const Color(0xFFFF8F78),
    onPrimary: const Color(0xFF5C1004),
    primaryContainer: const Color(0xFF7E1E0F),
    onPrimaryContainer: const Color(0xFFFFDAD3),
    secondary: const Color(0xFF8FD6A8),
    onSecondary: const Color(0xFF00391C),
    secondaryContainer: const Color(0xFF1B4D31),
    onSecondaryContainer: const Color(0xFFD5EEDD),
    tertiary: const Color(0xFFF2BE6B),
    onTertiary: const Color(0xFF452B00),
    tertiaryContainer: const Color(0xFF5E4100),
    onTertiaryContainer: const Color(0xFFFFE7C2),
    surface: const Color(0xFF121110),
    onSurface: const Color(0xFFEDEAE6),
    onSurfaceVariant: const Color(0xFFB5AFA8),
    surfaceContainerLowest: const Color(0xFF0D0C0B),
    surfaceContainerLow: const Color(0xFF1C1A19),
    surfaceContainer: const Color(0xFF222020),
    surfaceContainerHigh: const Color(0xFF2B2928),
    surfaceContainerHighest: const Color(0xFF353331),
    outline: const Color(0xFF857F78),
    outlineVariant: const Color(0xFF3A3735),
  );

  /// Color de las tarjetas: blanco en claro; un gris cálido en oscuro.
  static Color cardColor(ColorScheme s) =>
      s.brightness == Brightness.light ? s.surfaceContainerLowest : s.surfaceContainerLow;

  /// Botón redondo que va encima de una foto (regresar, favorito).
  static ButtonStyle overlayIconButton(ColorScheme s) =>
      IconButton.styleFrom(backgroundColor: cardColor(s), elevation: 1, shadowColor: Colors.black26);

  /// Sombra suave de dos capas (en oscuro se usa borde en su lugar).
  static List<BoxShadow> cardShadow(ColorScheme s) => s.brightness == Brightness.light
      ? const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 4)),
          BoxShadow(color: Color(0x0A000000), blurRadius: 2, offset: Offset(0, 1)),
        ]
      : const [];

  static TextTheme _textTheme(ColorScheme scheme) {
    // `black`/`white` solo traen color y familia; los tamaños de la escala de
    // Material 3 vienen en `englishLike`. Sin combinarlos, los estilos usados
    // directamente (p. ej. títulos de AppBar) salen a 14 px.
    final typography = Typography.material2021();
    final base = typography.englishLike
        .merge(scheme.brightness == Brightness.light ? typography.black : typography.white)
        .apply(fontFamily: sans, bodyColor: scheme.onSurface, displayColor: scheme.onSurface);

    TextStyle? heading(TextStyle? s, {double spacing = -.4}) =>
        s?.copyWith(fontWeight: FontWeight.w700, letterSpacing: spacing, height: 1.2);

    return base.copyWith(
      displayLarge: heading(base.displayLarge, spacing: -1),
      displayMedium: heading(base.displayMedium, spacing: -.8),
      displaySmall: heading(base.displaySmall, spacing: -.6),
      headlineLarge: heading(base.headlineLarge),
      headlineMedium: heading(base.headlineMedium),
      headlineSmall: heading(base.headlineSmall, spacing: -.3),
      titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -.2),
      titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      bodyMedium: base.bodyMedium?.copyWith(height: 1.45),
      bodySmall: base.bodySmall?.copyWith(height: 1.4, color: scheme.onSurfaceVariant),
    );
  }

  static ThemeData _build(ColorScheme scheme) {
    final text = _textTheme(scheme);
    final light = scheme.brightness == Brightness.light;
    const pill = StadiumBorder();
    OutlineInputBorder field(Color color, [double width = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusSm),
      borderSide: BorderSide(color: color, width: width),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: sans,
      textTheme: text,
      scaffoldBackgroundColor: scheme.surface,
      splashFactory: InkSparkle.splashFactory,
      // Material Symbols es una fuente variable: contorno por defecto y
      // relleno (fill: 1) en íconos activos o destacados.
      iconTheme: IconThemeData(color: scheme.onSurface, fill: 0, weight: 400, grade: 0, opticalSize: 24),
      // Transiciones de Material 3 por plataforma.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.fuchsia: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black26,
        titleTextStyle: text.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: cardColor(scheme),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: light ? BorderSide.none : BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: cardColor(scheme),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: field(scheme.outlineVariant),
        enabledBorder: field(scheme.outlineVariant),
        focusedBorder: field(scheme.primary, 2),
        errorBorder: field(scheme.error),
        focusedErrorBorder: field(scheme.error, 2),
        prefixIconColor: scheme.onSurfaceVariant,
        hintStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: pill,
          textStyle: const TextStyle(fontFamily: sans, fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: pill,
          side: BorderSide(color: scheme.outlineVariant),
          textStyle: const TextStyle(fontFamily: sans, fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(fontFamily: sans, fontWeight: FontWeight.w600),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          minimumSize: const Size(0, 44),
          // Las opciones no elegidas van en tono neutro, no en el color de acento.
          foregroundColor: scheme.onSurface,
          selectedBackgroundColor: scheme.primaryContainer,
          selectedForegroundColor: scheme.onPrimaryContainer,
          side: BorderSide(color: scheme.outlineVariant),
          textStyle: const TextStyle(fontFamily: sans, fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide(color: scheme.outlineVariant),
        backgroundColor: cardColor(scheme),
        selectedColor: scheme.onSurface,
        secondarySelectedColor: scheme.onSurface,
        labelStyle: text.labelLarge,
        secondaryLabelStyle: text.labelLarge?.copyWith(color: scheme.surface),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
      checkboxTheme: CheckboxThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        titleTextStyle: text.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
        subtitleTextStyle: text.bodySmall,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.onSurface,
        contentTextStyle: text.bodyMedium?.copyWith(color: scheme.surface),
        actionTextColor: light ? const Color(0xFFFFB4A6) : tomato,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor(scheme),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
        titleTextStyle: text.headlineSmall,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        showDragHandle: true,
        backgroundColor: cardColor(scheme),
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardColor(scheme),
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelMedium?.copyWith(
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? scheme.onSurface : scheme.onSurfaceVariant,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: cardColor(scheme),
        indicatorColor: scheme.primaryContainer,
        selectedLabelTextStyle: text.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelTextStyle: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        linearTrackColor: scheme.surfaceContainerHigh,
        linearMinHeight: 6,
      ),
    );
  }
}
