import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

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

  BluetoothDevice? _device;
  BluetoothCharacteristic? _writeCharacteristic;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<BluetoothAdapterState>? _adapterSubscription;

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

    _adapterSubscription = FlutterBluePlus.adapterState.listen((state) {
      if (state == BluetoothAdapterState.on) {
        if (_device == null) {
          connectionState.value = WatchConnectionState.disconnected;
          statusMessage.value = 'Bluetooth is on. Connect a watch to relay alerts';
        }
      } else {
        connectionState.value = WatchConnectionState.bluetoothOff;
        statusMessage.value = 'Bluetooth is off. Turn it on to connect your watch';
      }
    });
  }

  Future<bool> connectToWatch({Duration timeout = const Duration(seconds: 18)}) async {
    await initialize();

    if (connectionState.value == WatchConnectionState.unsupported) {
      return false;
    }

    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      connectionState.value = WatchConnectionState.bluetoothOff;
      statusMessage.value = 'Bluetooth is off. Please enable Bluetooth first';
      return false;
    }

    connectionState.value = WatchConnectionState.scanning;
    statusMessage.value = 'Scanning for smartwatch...';

    final device = await _scanForWatch(timeout: timeout);
    if (device == null) {
      connectionState.value = WatchConnectionState.disconnected;
      statusMessage.value = 'No smartwatch found. Keep watch nearby and retry';
      return false;
    }

    _device = device;
    connectionState.value = WatchConnectionState.connecting;
    statusMessage.value = 'Connecting to ${_friendlyDeviceName(device)}...';

    try {
      await device.connect(timeout: timeout);
    } catch (_) {
      // Already connected is fine; proceed with discovery.
    }

    _connectionSubscription?.cancel();
    _connectionSubscription = device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        _writeCharacteristic = null;
        connectionState.value = WatchConnectionState.disconnected;
        statusMessage.value = 'Watch disconnected';
      }
    });

    final services = await device.discoverServices();
    _writeCharacteristic = _findWritableCharacteristic(services);

    if (_writeCharacteristic == null) {
      connectionState.value = WatchConnectionState.noWritableCharacteristic;
      statusMessage.value =
          'Connected, but no writable alert channel found on this watch';
      return false;
    }

    connectionState.value = WatchConnectionState.connected;
    statusMessage.value =
        'Connected to ${_friendlyDeviceName(device)}. Alerts relay is ready';
    return true;
  }

  Future<void> disconnect() async {
    final device = _device;
    _writeCharacteristic = null;
    _device = null;

    if (device != null) {
      await device.disconnect();
    }

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
      await _writeCharacteristic!.write(
        utf8.encode(payload),
        withoutResponse: _writeCharacteristic!.properties.writeWithoutResponse,
      );
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

  Future<BluetoothDevice?> _scanForWatch({
    required Duration timeout,
  }) async {
    final completer = Completer<BluetoothDevice?>();

    final scanSub = FlutterBluePlus.scanResults.listen((results) {
      for (final result in results) {
        final name = _friendlyDeviceName(result.device).toLowerCase();
        if (_looksLikeWatch(name)) {
          if (!completer.isCompleted) {
            completer.complete(result.device);
          }
          return;
        }
      }
    });

    try {
      await FlutterBluePlus.startScan(timeout: timeout);
      await Future<void>.delayed(timeout);
      if (!completer.isCompleted) {
        completer.complete(null);
      }
      return completer.future;
    } finally {
      await FlutterBluePlus.stopScan();
      await scanSub.cancel();
    }
  }

  BluetoothCharacteristic? _findWritableCharacteristic(
    List<BluetoothService> services,
  ) {
    for (final service in services) {
      for (final characteristic in service.characteristics) {
        if (characteristic.properties.write ||
            characteristic.properties.writeWithoutResponse) {
          return characteristic;
        }
      }
    }
    return null;
  }

  bool _looksLikeWatch(String name) {
    return name.contains('watch') ||
        name.contains('band') ||
        name.contains('wear') ||
        name.contains('fit');
  }

  String _friendlyDeviceName(BluetoothDevice device) {
    final platformName = device.platformName.trim();
    if (platformName.isNotEmpty) {
      return platformName;
    }
    return device.remoteId.str;
  }

  String _buildPayload({
    required String title,
    required String message,
    required DateTime createdAt,
  }) {
    final safeTitle = title.replaceAll('|', '/').trim();
    final safeMessage = message.replaceAll('|', '/').trim();
    final compactMessage =
        safeMessage.length > 100 ? '${safeMessage.substring(0, 100)}...' : safeMessage;
    return 'ALERT|${_formatTime(createdAt)}|$safeTitle|$compactMessage';
  }

  String _formatTime(DateTime value) {
    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}

