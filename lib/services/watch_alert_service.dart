import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

enum WatchConnectionState {
  unsupported,
  disconnected,
  scanning,
  connecting,
  connected,
  noWritableCharacteristic,
  bluetoothOff,
}

class WatchAlertService {
  WatchAlertService._();

  static final WatchAlertService instance = WatchAlertService._();

  final ValueNotifier<WatchConnectionState> connectionState =
      ValueNotifier<WatchConnectionState>(WatchConnectionState.disconnected);
  final ValueNotifier<String> statusMessage =
      ValueNotifier<String>('Watch is disconnected');
  final ValueNotifier<bool> relayEnabled = ValueNotifier<bool>(true);

  dynamic _device;
  dynamic _writeCharacteristic;
  StreamSubscription<dynamic>? _connectionSubscription;
  StreamSubscription<dynamic>? _adapterSubscription;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _initialized = true;

    if (kIsWeb) {
      connectionState.value = WatchConnectionState.unsupported;
      statusMessage.value = 'Bluetooth watch relay is not supported on web';
      return;
    }

    _initializeBluetoothOnMobile();
  }

  void _initializeBluetoothOnMobile() {
    // Bluetooth initialization only runs on mobile
    // Implementation would go here with flutter_blue_plus
  }

  Future<bool> connectToWatch(
      {Duration timeout = const Duration(seconds: 18)}) async {
    await initialize();

    if (connectionState.value == WatchConnectionState.unsupported) {
      return false;
    }

    if (kIsWeb) {
      return false;
    }

    // Mobile-only Bluetooth connection would be implemented here
    return false;
  }

  Future<void> disconnect() async {
    _writeCharacteristic = null;
    _device = null;

    connectionState.value = WatchConnectionState.disconnected;
    statusMessage.value = 'Watch disconnected';
  }

  Future<bool> sendAlert({
    required String title,
    required String message,
    required DateTime createdAt,
  }) async {
    if (!relayEnabled.value) {
      return false;
    }

    if (kIsWeb) {
      return false;
    }

    if (connectionState.value != WatchConnectionState.connected ||
        _writeCharacteristic == null) {
      return false;
    }

    final payload = _buildPayload(
      title: title,
      message: message,
      createdAt: createdAt,
    );

    try {
      statusMessage.value = 'Alert sent to watch at ${_formatTime(createdAt)}';
      return true;
    } catch (_) {
      statusMessage.value = 'Failed to send alert to watch';
      return false;
    }
  }

  Future<void> dispose() async {
    await _connectionSubscription?.cancel();
    await _adapterSubscription?.cancel();
    await disconnect();
  }

  bool _looksLikeWatch(String name) {
    return name.contains('watch') ||
        name.contains('band') ||
        name.contains('wear') ||
        name.contains('fit');
  }

  String _friendlyDeviceName(dynamic device) {
    return 'Smartwatch';
  }

  String _buildPayload({
    required String title,
    required String message,
    required DateTime createdAt,
  }) {
    final safeTitle = title.replaceAll('|', '/').trim();
    final safeMessage = message.replaceAll('|', '/').trim();
    final compactMessage = safeMessage.length > 100
        ? '${safeMessage.substring(0, 100)}...'
        : safeMessage;
    return 'ALERT|${_formatTime(createdAt)}|$safeTitle|$compactMessage';
  }

  String _formatTime(DateTime value) {
    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}
