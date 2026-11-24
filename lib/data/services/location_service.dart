import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../models/delivery_location.dart';

class LocationException implements Exception {
  const LocationException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Ubicación actual del dispositivo.
abstract interface class LocationService {
  Future<DeliveryLocation> current();
}

/// Usa el GPS (o la ubicación del navegador en web) con permiso del usuario.
class DeviceLocationService implements LocationService {
  const DeviceLocationService();

  @override
  Future<DeliveryLocation> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException('Activa la ubicación de tu dispositivo.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      throw const LocationException('No diste permiso para usar tu ubicación.');
    }
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 15)),
      );
      return DeliveryLocation(latitude: position.latitude, longitude: position.longitude, accuracy: position.accuracy);
    } on TimeoutException {
      throw const LocationException('No pudimos obtener tu ubicación a tiempo. Intenta de nuevo.');
    }
  }
}
