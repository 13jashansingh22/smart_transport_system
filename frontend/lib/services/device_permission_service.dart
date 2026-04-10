import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionRequestResult {
  const PermissionRequestResult({
    required this.granted,
    required this.permanentlyDenied,
    this.message,
  });

  final bool granted;
  final bool permanentlyDenied;
  final String? message;
}

class DevicePermissionService {
  DevicePermissionService._();

  static Future<PermissionRequestResult> ensureLocationPermission() async {
    if (kIsWeb) {
      return const PermissionRequestResult(
        granted: true,
        permanentlyDenied: false,
        message: 'Web browsers manage location permissions automatically.',
      );
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const PermissionRequestResult(
          granted: false,
          permanentlyDenied: false,
          message: 'Location services are turned off on this device.',
        );
      }

      final currentStatus = await Permission.locationWhenInUse.status;
      if (currentStatus.isGranted || currentStatus.isLimited) {
        return const PermissionRequestResult(
          granted: true,
          permanentlyDenied: false,
        );
      }

      final requestedStatus = await Permission.locationWhenInUse.request();
      if (requestedStatus.isGranted || requestedStatus.isLimited) {
        return const PermissionRequestResult(
          granted: true,
          permanentlyDenied: false,
        );
      }

      if (requestedStatus.isPermanentlyDenied) {
        return const PermissionRequestResult(
          granted: false,
          permanentlyDenied: true,
          message:
              'Location permission is permanently denied. Open settings to enable it.',
        );
      }

      return const PermissionRequestResult(
        granted: false,
        permanentlyDenied: false,
        message: 'Location permission was denied.',
      );
    } catch (_) {
      return const PermissionRequestResult(
        granted: false,
        permanentlyDenied: false,
        message: 'Unable to request location permission on this device.',
      );
    }
  }
}

