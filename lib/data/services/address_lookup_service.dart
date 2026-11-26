import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/delivery_location.dart';

/// Convierte un punto del GPS en una dirección escrita.
abstract interface class AddressLookupService {
  /// Calle, número y colonia del punto, o null si no se encontró.
  Future<String?> addressFor(DeliveryLocation location);
}

/// Geocodificación inversa con Nominatim, el servicio de búsqueda de
/// OpenStreetMap. Es gratuito y no pide llave, pero su política de uso limita
/// a una consulta por segundo: solo se llama cuando el cliente toca
/// "Usar mi ubicación".
class NominatimAddressService implements AddressLookupService {
  NominatimAddressService({http.Client? client, this.timeout = const Duration(seconds: 8)})
    : _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout;

  static Uri urlFor(DeliveryLocation l) => Uri.https('nominatim.openstreetmap.org', '/reverse', {
    'format': 'jsonv2',
    'lat': l.latitude.toStringAsFixed(6),
    'lon': l.longitude.toStringAsFixed(6),
    'zoom': '18',
    'addressdetails': '1',
    'accept-language': 'es',
  });

  @override
  Future<String?> addressFor(DeliveryLocation location) async {
    try {
      final res = await _client.get(urlFor(location)).timeout(timeout);
      if (res.statusCode != 200) return null;
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      if (body is! Map || body['address'] is! Map) return null;
      return formatAddress(Map<String, dynamic>.from(body['address'] as Map));
    } catch (_) {
      // Sin internet o el servicio no respondió: el cliente escribe la dirección.
      return null;
    }
  }

  /// "Calle 60 #123, Centro, Mérida" a partir de los campos de Nominatim.
  static String? formatAddress(Map<String, dynamic> a) {
    String? first(List<String> keys) {
      for (final k in keys) {
        final v = a[k];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
      return null;
    }

    final road = first(['road', 'pedestrian', 'street']);
    final number = first(['house_number']);
    final colonia = first(['neighbourhood', 'suburb', 'quarter', 'residential']);
    final city = first(['city', 'town', 'village', 'municipality']);
    final street = road == null ? null : (number == null ? road : '$road #$number');
    final parts = [?street, ?colonia, ?city];
    return street == null ? null : parts.join(', ');
  }
}
