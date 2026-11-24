import 'dart:math' as math;

sealed class Coupon {
  const Coupon(this.code, this.label, {this.firstOrderOnly = false});

  final String code;
  final String label;

  /// Solo vale si el usuario todavía no ha hecho ningún pedido.
  final bool firstOrderOnly;

  double discountFor(double subtotal) => switch (this) {
    PercentCoupon(:final percent) => subtotal * percent / 100,
    FixedCoupon(:final amount) => math.min(amount, subtotal),
  };
}

final class PercentCoupon extends Coupon {
  const PercentCoupon(super.code, super.label, this.percent, {super.firstOrderOnly});
  final double percent;
}

final class FixedCoupon extends Coupon {
  const FixedCoupon(super.code, super.label, this.amount, {super.firstOrderOnly});
  final double amount;
}
