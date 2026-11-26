import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pizzago/core/utils/validators.dart';
import 'package:pizzago/data/models/delivery_location.dart';
import 'package:pizzago/data/repositories/firebase_auth_repository.dart';
import 'package:pizzago/data/services/address_lookup_service.dart';

void main() {
  group('Contraseña nueva', () {
    test('pide 8 caracteres con letras y números', () {
      expect(Validators.newPassword(''), isNotNull);
      expect(Validators.newPassword('abc123'), 'Mínimo 8 caracteres');
      expect(Validators.newPassword('pizzapizza'), 'Usa letras y números');
      expect(Validators.newPassword('12345678'), 'Usa letras y números');
      expect(Validators.newPassword('pizzago123'), isNull);
    });
  });

  group('Mensajes de Firebase Authentication', () {
    test('no revelan si el correo existe', () {
      final wrong = FirebaseAuthRepository.authMessage('wrong-password');
      expect(FirebaseAuthRepository.authMessage('user-not-found'), wrong);
      expect(FirebaseAuthRepository.authMessage('invalid-credential'), wrong);
    });

    test('avisan del bloqueo por intentos y de errores desconocidos', () {
      expect(FirebaseAuthRepository.authMessage('too-many-requests'), contains('demasiados intentos'));
      expect(FirebaseAuthRepository.authMessage('algo-nuevo'), contains('Intenta de nuevo'));
    });
  });

  group('Dirección con OpenStreetMap (Nominatim)', () {
    const punto = DeliveryLocation(latitude: 20.967370, longitude: -89.623710, accuracy: 12);

    test('arma la consulta de geocodificación inversa', () {
      final url = NominatimAddressService.urlFor(punto);
      expect(url.host, 'nominatim.openstreetmap.org');
      expect(url.path, '/reverse');
      expect(url.queryParameters, containsPair('lat', '20.967370'));
      expect(url.queryParameters, containsPair('lon', '-89.623710'));
      expect(url.queryParameters, containsPair('accept-language', 'es'));
    });

    test('escribe calle, número, colonia y ciudad', () {
      expect(
        NominatimAddressService.formatAddress({
          'road': 'Calle 60',
          'house_number': '491',
          'suburb': 'Centro',
          'city': 'Mérida',
        }),
        'Calle 60 #491, Centro, Mérida',
      );
      expect(NominatimAddressService.formatAddress({'road': 'Calle 60', 'town': 'Umán'}), 'Calle 60, Umán');
      expect(NominatimAddressService.formatAddress({'city': 'Mérida'}), isNull);
    });

    test('lee la respuesta del servicio', () async {
      final service = NominatimAddressService(
        client: MockClient((req) async {
          expect(req.url.host, 'nominatim.openstreetmap.org');
          return http.Response.bytes(
            utf8.encode(jsonEncode({
              'address': {'road': 'Calle 60', 'house_number': '491', 'neighbourhood': 'Centro', 'city': 'Mérida'},
            })),
            200,
          );
        }),
      );
      expect(await service.addressFor(punto), 'Calle 60 #491, Centro, Mérida');
    });

    test('sin respuesta válida devuelve null y no rompe el pago', () async {
      final caido = NominatimAddressService(client: MockClient((_) async => http.Response('', 503)));
      expect(await caido.addressFor(punto), isNull);
      final sinRed = NominatimAddressService(client: MockClient((_) async => throw http.ClientException('sin red')));
      expect(await sinRed.addressFor(punto), isNull);
    });
  });
}
