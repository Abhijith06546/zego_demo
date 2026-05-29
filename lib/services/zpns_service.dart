import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:zego_zpns/zego_zpns.dart';

import 'call_notification_service.dart';

/// Call this once after every successful ZIM connectUser.
/// ZPNs fetches the FCM token and binds it to the logged-in ZIM user so
/// ZEGO's backend knows where to send offline call push notifications.
Future<void> initZPNs() async {
  if (kIsWeb) return;

  // Set handlers BEFORE registerPush so we never miss the registration callback.
  ZPNsEventHandler.onRegistered = (msg) {
    debugPrint('ZPNs registered → pushID: ${msg.pushID}  err: ${msg.errorCode}');
  };

  // Fired when a data-only push arrives while the app is backgrounded but alive.
  ZPNsEventHandler.onThroughMessageReceived = (message) async {
    await showCallKitFromZPNsMessage(message);
  };

  ZPNs.setPushConfig(ZPNsConfig()..enableFCMPush = true);
  await ZPNs.getInstance().registerPush();
}

/// Shared helper used by both the background isolate handler and
/// the foreground [onThroughMessageReceived] callback.
Future<void> showCallKitFromZPNsMessage(ZPNsMessage message) async {
  final title = message.title;
  final content = message.content;
  // In zego_zpns 2.6.x the ZIM push payload arrives in extras['payload']
  final payload = (message.extras['payload'] as String?) ?? '';

  var callerName = 'Incoming Call';
  if (content.contains(' is calling you')) {
    callerName = content.split(' is calling you').first.trim();
  } else if (content.isNotEmpty) {
    callerName = content;
  }

  var isVideo = title.toLowerCase().contains('video');
  if (payload.isNotEmpty) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map) isVideo = decoded['type'] == 2;
    } catch (_) {}
  }

  await CallNotificationService.showIncomingCall(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    callerName: callerName,
    isVideo: isVideo,
  );
}
