import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CallNotificationService {
  static const _pendingAcceptKey = 'pending_background_accept';

  static Future<void> showIncomingCall({
    required String id,
    required String callerName,
    required bool isVideo,
  }) async {
    final params = CallKitParams(
      id: id,
      nameCaller: callerName,
      appName: 'CallFrnd',
      type: isVideo ? 1 : 0,
      duration: 55000,
      textAccept: 'Accept',
      textDecline: 'Decline',
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        isShowFullLockedScreen: true,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#0D1B2A',
        actionColor: '#4CAF50',
        textColor: '#ffffff',
        incomingCallNotificationChannelName: 'Incoming Call',
        missedCallNotificationChannelName: 'Missed Call',
      ),
    );
    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  static Future<void> endAll() async {
    await FlutterCallkitIncoming.endAllCalls();
  }

  static Future<void> markAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pendingAcceptKey, true);
  }

  static Future<bool> hasPendingAccept() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_pendingAcceptKey) ?? false;
  }

  static Future<void> clearPendingAccept() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingAcceptKey);
  }
}
