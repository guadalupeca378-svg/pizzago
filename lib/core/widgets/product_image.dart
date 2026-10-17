import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../data/models/pizza.dart';

/// Fotografías de assets/images/ (créditos en assets/images/CREDITOS.md).
abstract final class AppImages {
  static String product(String id) => 'assets/images/products/$id.jpg';
  static String topping(String topping) => 'assets/images/toppings/$topping.jpg';
}

Widget _photo(String path, {IconData fallback = Symbols.local_pizza_rounded, Alignment alignment = Alignment.center}) =>
    Image.asset(
      path,
      fit: BoxFit.cover,
      alignment: alignment,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      // Si ya estaba en caché aparece al instante; si no, entra con un fundido.
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) => wasSynchronouslyLoaded
          ? child
          : AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              child: child,
            ),
      errorBuilder: (context, _, _) => ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        child: Center(child: Icon(fallback, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ),
    );

/// Precarga las fotos de cada producto en cuanto llega el menú, para que no
/// haya "huecos" al navegar.
class ImagePrecacher extends StatefulWidget {
  const ImagePrecacher({super.key, required this.productIds, required this.child});

  final List<String> productIds;
  final Widget child;

  @override
  State<ImagePrecacher> createState() => _ImagePrecacherState();
}

class _ImagePrecacherState extends State<ImagePrecacher> {
  final _done = <String>{};

  void _precache(Iterable<String> paths) {
    for (final path in paths) {
      if (_done.add(path)) {
        precacheImage(AssetImage(path), context).ignore();
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precache(widget.productIds.map(AppImages.product));
  }

  @override
  void didUpdateWidget(ImagePrecacher old) {
    super.didUpdateWidget(old);
    _precache(widget.productIds.map(AppImages.product));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Foto del producto; llena el espacio que le den (recorte tipo "cover").
class ProductImage extends StatelessWidget {
  const ProductImage({super.key, required this.pizza, this.alignment = Alignment.center});

  final Pizza pizza;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => _photo(AppImages.product(pizza.id), alignment: alignment);
}

class ToppingImage extends StatelessWidget {
  const ToppingImage({super.key, required this.topping, required this.size});

  final String topping;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: _photo(AppImages.topping(topping), fallback: Symbols.add_circle_rounded),
  );
}
