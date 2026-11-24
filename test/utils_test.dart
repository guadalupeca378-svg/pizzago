import 'package:flutter_test/flutter_test.dart';
import 'package:pizzago/core/utils/formatters.dart';
import 'package:pizzago/core/utils/validators.dart';

void main() {
  test('cuenta en singular y plural', () {
    expect(Fmt.count(1, 'producto'), '1 producto');
    expect(Fmt.count(3, 'producto'), '3 productos');
    expect(Fmt.count(0, 'pedido'), '0 pedidos');
  });

  test('un campo opcional acepta vacío o solo espacios, pero no basura', () {
    final phone = Validators.optional(Validators.phone);
    expect(phone(''), isNull);
    expect(phone('   '), isNull);
    expect(phone('123'), 'Debe tener 10 dígitos');
    expect(phone('5512345678'), isNull);
  });
}
