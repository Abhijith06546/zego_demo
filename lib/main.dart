import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:zego_zpns/zego_zpns.dart';

import 'app_globals.dart';
import 'pages/call/call_controller.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'services/call_notification_service.dart';
import 'services/zpns_service.dart';
import 'utils/network_aware_wrapper.dart';
import 'utils/zegocloud_token.dart';
import 'zego_call_manager.dart';
import 'zego_sdk_key_center.dart';

// Called by ZPNs when a call push arrives while the app is killed.
// Must be top-level with @pragma so the Dart compiler keeps it.
@pragma('vm:entry-point')
Future<void> _zpnsBackgroundHandler(ZPNsMessage message) async {
  await showCallKitFromZPNsMessage(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Must be set BEFORE runApp so the background isolate can find the handler.
  ZPNs.setBackgroundMessageHandler(_zpnsBackgroundHandler);

  if (!kIsWeb) {
    await Firebase.initializeApp();
  }

  // Listen to CallKit button events (accept / decline on lock screen).
  FlutterCallkitIncoming.onEvent.listen((event) async {
    if (event == null) return;
    switch (event.event) {
      case Event.actionCallAccept:
        if (ZegoCallManager().currentCallData != null) {
          // App was backgrounded — ZIM already delivered the call.
          // Accept it directly without waiting for a re-delivery.
          ZegoCallController().acceptCall();
        } else {
          // App was killed — ZIM hasn't reconnected yet.
          // Flag it so call_controller auto-accepts once ZIM delivers.
          await CallNotificationService.markAccepted();
        }
        break;
      case Event.actionCallDecline:
      case Event.actionCallTimeout:
        await CallNotificationService.endAll();
        break;
      default:
        break;
    }
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'CallFrnd Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AuthGate(),
      builder: (context, child) => NetworkAwareWrapper(child: child!),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAuth());
  }

  Future<void> _checkAuth() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      debugPrint('🔒 No saved session — showing login');
      _goLogin();
      return;
    }

    debugPrint('🔄 Session found for ${firebaseUser.email} — auto-connecting...');

    try {
      // Fetch profile (try executives, fallback to users)
      var doc = await FirebaseFirestore.instance
          .collection('executives')
          .doc(firebaseUser.uid)
          .get();
      if (!doc.exists) {
        doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .get();
      }
      if (!doc.exists) {
        debugPrint('⚠️ Profile not found — clearing session');
        await FirebaseAuth.instance.signOut();
        _goLogin();
        return;
      }

      final data = doc.data()!;
      final zegoCallID = data['zegoCallID'] as String;
      final fullName = '${data['firstName']} ${data['lastName']}';

      await ZEGOSDKManager().init(
          SDKKeyCenter.appID, kIsWeb ? null : SDKKeyCenter.appSign);
      ZegoCallManager().addListener();
      ZegoCallController().initService();

      String? token;
      if (kIsWeb) {
        token = ZegoTokenUtils.generateToken(
            SDKKeyCenter.appID, SDKKeyCenter.serverSecret, zegoCallID);
      }

      await ZEGOSDKManager().connectUser(zegoCallID, fullName, token: token);
      ZEGOSDKManager().zimService.updateUserAvatarUrl(
        'https://robohash.org/$zegoCallID.png?set=set4',
      );
      initZPNs();

      debugPrint('✅ login aayi monee — auto-login: $zegoCallID');
      _goHome();
    } catch (e) {
      debugPrint('❌ Auto-login failed: $e — falling back to login screen');
      _goLogin();
    }
  }

  void _goHome() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  void _goLogin() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (_) => const LoginPage(title: 'Login Page')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF2F3F5),
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFF0D1B2A)),
      ),
    );
  }
}
