import 'package:intl/intl.dart';

abstract final class Fmt {
  static final _money0 = NumberFormat.currency(locale: 'es_MX', symbol: r'$', decimalDigits: 0);
  static final _money2 = NumberFormat.currency(locale: 'es_MX', symbol: r'$', decimalDigits: 2);

  /// `$159` para cantidades cerradas y `$143.10` cuando hay centavos.
  static String money(double value) => (value == value.roundToDouble() ? _money0 : _money2).format(value);

  static String dateTime(DateTime d) => DateFormat("d 'de' MMMM, HH:mm", 'es_MX').format(d);

  static String time(DateTime d) => DateFormat.Hm('es_MX').format(d);

  /// "1 producto" / "3 productos". El plural por defecto agrega una "s".
  static String count(int n, String singular, [String? plural]) =>
      n == 1 ? '1 $singular' : '$n ${plural ?? '${singular}s'}';
}
