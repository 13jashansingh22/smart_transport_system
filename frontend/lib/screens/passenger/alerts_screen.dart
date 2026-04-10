import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/smart_transport_ai_service.dart';
import '../../services/watch_alert_service.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final service = SmartTransportAIService.instance;
  final watchService = WatchAlertService.instance;

  String? _lastForwardedAlertId;

  @override
  void initState() {
    super.initState();
    service.startNotificationFeed();
    unawaited(watchService.initialize());
    service.notifications.addListener(_forwardLatestAlertToWatch);
  }

  @override
  void dispose() {
    service.notifications.removeListener(_forwardLatestAlertToWatch);
    super.dispose();
  }

  Future<void> _forwardLatestAlertToWatch() async {
    final alerts = service.notifications.value;
    if (alerts.isEmpty) {
      return;
    }

    final latest = alerts.first;
    if (_lastForwardedAlertId == latest.id) {
      return;
    }

    _lastForwardedAlertId = latest.id;
    await watchService.sendAlert(
      title: latest.title,
      message: latest.message,
      createdAt: latest.createdAt,
    );
  }

  String _stateLabel(WatchConnectionState state) {
    switch (state) {
      case WatchConnectionState.unsupported:
        return 'Unsupported';
      case WatchConnectionState.disconnected:
        return 'Disconnected';
      case WatchConnectionState.scanning:
        return 'Scanning';
      case WatchConnectionState.connecting:
        return 'Connecting';
      case WatchConnectionState.connected:
        return 'Connected';
      case WatchConnectionState.noWritableCharacteristic:
        return 'Connected (Read Only)';
      case WatchConnectionState.bluetoothOff:
        return 'Bluetooth Off';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Real-Time Notifications')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ValueListenableBuilder<WatchConnectionState>(
                      valueListenable: watchService.connectionState,
                      builder: (_, state, __) => Row(
                        children: [
                          const Icon(Icons.watch_outlined),
                          const SizedBox(width: 8),
                          Text('Watch: ${_stateLabel(state)}'),
                          const Spacer(),
                          FilledButton.tonal(
                            onPressed: state == WatchConnectionState.connected
                                ? watchService.disconnect
                                : watchService.connectToWatch,
                            child: Text(
                              state == WatchConnectionState.connected
                                  ? 'Disconnect'
                                  : 'Connect',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ValueListenableBuilder<String>(
                      valueListenable: watchService.statusMessage,
                      builder: (_, text, __) => Text(text),
                    ),
                    const SizedBox(height: 8),
                    ValueListenableBuilder<bool>(
                      valueListenable: watchService.relayEnabled,
                      builder: (_, enabled, __) => SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Relay alerts to smartwatch'),
                        value: enabled,
                        onChanged: (value) {
                          watchService.relayEnabled.value = value;
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<List<AppNotification>>(
              valueListenable: service.notifications,
              builder: (_, alerts, __) {
                if (alerts.isEmpty) {
                  return const Center(child: Text('Waiting for live alerts...'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (_, index) {
                    final item = alerts[index];
                    return ListTile(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      tileColor: Theme.of(context).cardColor,
                      leading: const Icon(Icons.notifications_active),
                      title: Text(item.title),
                      subtitle: Text(item.message),
                      trailing: Text(
                        '${item.createdAt.hour.toString().padLeft(2, '0')}:${item.createdAt.minute.toString().padLeft(2, '0')}',
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemCount: alerts.length,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
