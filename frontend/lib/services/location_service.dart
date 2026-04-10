import 'package:geolocator/geolocator.dart';

import 'device_permission_service.dart';

class LocationFetchResult {
  final double latitude;
  final double longitude;
  final bool usedFallback;
  final String? message;

  const LocationFetchResult({
    required this.latitude,
    required this.longitude,
    required this.usedFallback,
    this.message,
  });
}

class LocationService {
  static Future<LocationFetchResult> getCurrentCoordinates({
    required double fallbackLatitude,
    required double fallbackLongitude,
  }) async {
    Future<LocationFetchResult> fallback(String message) async {
      return LocationFetchResult(
        latitude: fallbackLatitude,
        longitude: fallbackLongitude,
        usedFallback: true,
        message: message,
      );
    }

    try {
      final permission = await DevicePermissionService.ensureLocationPermission();
      if (!permission.granted) {
        return fallback(
          permission.message ??
              'Location permission denied. Showing default city point.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return LocationFetchResult(
        latitude: position.latitude,
        longitude: position.longitude,
        usedFallback: false,
      );
    } catch (_) {
      return fallback('Could not fetch live location. Using fallback point.');
    }
  }
}
