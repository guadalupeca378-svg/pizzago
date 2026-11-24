import 'package:flutter/foundation.dart';

/// Punto de entrega tomado del GPS del dispositivo.
@immutable
class DeliveryLocation {
  const DeliveryLocation({required this.latitude, required this.longitude, required this.accuracy});

  factory DeliveryLocation.fromMap(Map<String, dynamic> map) => DeliveryLocation(
    latitude: (map['latitude'] as num).toDouble(),
    longitude: (map['longitude'] as num).toDouble(),
    accuracy: (map['accuracy'] as num).toDouble(),
  );

  final double latitude;
  final double longitude;

  /// Margen de error en metros que reporta el dispositivo.
  final double accuracy;

  /// Texto corto para mostrar: "17.98912, -92.94752 (±18 m)".
  String get label => '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)} (±${accuracy.round()} m)';

  /// Enlace que abre el punto en un mapa.
  Uri get mapUrl => Uri.https('www.google.com', '/maps/search/', {
    'api': '1',
    'query': '${latitude.toStringAsFixed(6)},${longitude.toStringAsFixed(6)}',
  });

  Map<String, dynamic> toMap() => {'latitude': latitude, 'longitude': longitude, 'accuracy': accuracy};

  @override
  bool operator ==(Object other) =>
      other is DeliveryLocation &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.accuracy == accuracy;

  @override
  int get hashCode => Object.hash(latitude, longitude, accuracy);
}
