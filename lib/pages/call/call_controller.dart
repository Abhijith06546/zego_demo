import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../app_globals.dart';
import '../../components/components.dart';
import '../../services/call_notification_service.dart';
import '../../zego_call_manager.dart';
import 'calling_page.dart';
import 'waiting_page.dart';

class ZegoCallController {
  ZegoCallController._internal();
  factory ZegoCallController() => instance;
  static final ZegoCallController instance = ZegoCallController._internal();

  List<StreamSubscription> subscriptions = [];

  bool dialogIsShowing = false;
  bool waitingPageIsShowing = false;
  bool callingPageIsShowing = false;

  BuildContext get context => navigatorKey.currentState!.overlay!.context;

  void initService() {
    final callManager = ZegoCallManager();
    subscriptions.addAll([
      callManager.incomingCallInvitationReceivedStreamCtrl.stream.listen(
        onIncomingCallInvitationReceived,
      ),
      callManager.incomingCallInvitationTimeoutStreamCtrl.stream.listen(
        onIncomingCallInvitationTimeout,
      ),
      callManager.onCallStartStreamCtrl.stream.listen(onCallStart),
      callManager.onCallEndStreamCtrl.stream.listen(onCallEnd),
    ]);
  }

  Future<void> onIncomingCallInvitationReceived(
    IncomingCallInvitationReceivedEvent event,
  ) async {
    await CallNotificationService.endAll();

    final extendedData = jsonDecode(event.info.extendedData);
    if (extendedData is Map && extendedData.containsKey('type')) {
      final callType = extendedData['type'];
      if (ZegoCallManager().isCallBusiness(callType)) {
        final inRoom = ZEGOSDKManager().expressService.currentRoomID.isNotEmpty;
        if (inRoom ||
            (ZegoCallManager().currentCallData?.callID != event.callID)) {
          final rejectExtendedData = {
            'type': callType,
            'reason': 'busy',
            'callID': event.callID
          };
          ZegoCallManager().rejectCallInvitationCauseBusy(
            event.callID,
            jsonEncode(rejectExtendedData),
            ZegoCallTypeExtension.fromInt(callType),
          );
          return;
        }

        // When backgrounded, ZIM still delivers the call but the Flutter dialog
        // is invisible. Show a native CallKit notification instead.
        final appState = WidgetsBinding.instance.lifecycleState;
        if (appState != AppLifecycleState.resumed) {
          final callerID = event.info.inviter;
          final callerName =
              ZEGOSDKManager().getUser(callerID)?.userName ?? 'Incoming Call';
          await CallNotificationService.showIncomingCall(
            id: event.callID,
            callerName: callerName,
            isVideo: callType == VIDEO_Call,
          );
          return;
        }

        // If the user already tapped Accept on the lock-screen CallKit UI,
        // auto-accept without showing the dialog again.
        final pendingAccept = await CallNotificationService.hasPendingAccept();
        await CallNotificationService.clearPendingAccept();
        if (pendingAccept) {
          acceptCall();
          return;
        }

        // Guard: call may have ended during the awaits above.
        if (navigatorKey.currentState == null) return;
        if (ZegoCallManager().currentCallData == null) return;

        dialogIsShowing = true;
        showTopModalSheet(
          context, // ignore: use_build_context_synchronously
          GestureDetector(
            onTap: onIncomingCallDialogClicked,
            child: ZegoCallInvitationDialog(
              invitationData: ZegoCallManager().currentCallData!,
              onAcceptCallback: acceptCall,
              onRejectCallback: rejectCall,
            ),
          ),
          barrierDismissible: false,
        );
      }
    }
  }

  void onIncomingCallInvitationTimeout(IncomingUserRequestTimeoutEvent event) {
    hideIncomingCallDialog();
    hideWaitingPage();
  }

  void onCallStart(dynamic event) {
    hideWaitingPage();
    pushToCallingPage();
  }

  void onCallEnd(dynamic event) {
    hideIncomingCallDialog();
    hideWaitingPage();
    hideCallingPage();
  }

  Future<void> acceptCall() async {
    hideIncomingCallDialog();
    final callID = ZegoCallManager().currentCallData?.callID;
    if (callID == null) return;
    ZegoCallManager().acceptCallInvitation(callID);
  }

  Future<void> rejectCall() async {
    hideIncomingCallDialog();
    final callID = ZegoCallManager().currentCallData?.callID;
    if (callID == null) return;
    ZegoCallManager().rejectCallInvitation(callID);
  }

  Future<T?> showTopModalSheet<T>(BuildContext context, Widget widget,
      {bool barrierDismissible = true}) {
    return showGeneralDialog<T?>(
      context: context,
      barrierDismissible: barrierDismissible,
      transitionDuration: const Duration(milliseconds: 250),
      barrierLabel: MaterialLocalizations.of(context).dialogLabel,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      pageBuilder: (context, _, __) => SafeArea(
          child: Column(
        children: [
          const SizedBox(height: 16),
          widget,
        ],
      )),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position:
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)
                  .drive(
            Tween<Offset>(begin: const Offset(0, -1.0), end: Offset.zero),
          ),
          child: child,
        );
      },
    );
  }

  void onIncomingCallDialogClicked() {
    hideIncomingCallDialog();
    pushToCallWaitingPage();
  }

  void hideIncomingCallDialog() {
    if (dialogIsShowing) {
      dialogIsShowing = false;
      final context = navigatorKey.currentState!.overlay!.context;
      Navigator.of(context).pop();
    }
  }

  void pushToCallWaitingPage() {
    waitingPageIsShowing = true;
    final context = navigatorKey.currentState!.overlay!.context;
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => CallWaitingPage(
          callData: ZegoCallManager().currentCallData!,
        ),
      ),
    );
  }

  void hideWaitingPage() {
    if (waitingPageIsShowing) {
      waitingPageIsShowing = false;
      final context = navigatorKey.currentState!.overlay!.context;
      Navigator.of(context).pop();
    }
  }

  void pushToCallingPage() {
    if (ZegoCallManager().currentCallData != null) {
      callingPageIsShowing = true;
      Navigator.push(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => CallingPage(
            callData: ZegoCallManager().currentCallData!,
          ),
        ),
      );
    }
  }

  void hideCallingPage() {
    if (callingPageIsShowing) {
      callingPageIsShowing = false;
      final context = navigatorKey.currentState!.overlay!.context;
      Navigator.of(context).pop();
    }
  }
}
