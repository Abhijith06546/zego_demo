import 'dart:async';

import 'package:floating/floating.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../components/common/zego_pip_button.dart';
import '../../components/components.dart';
import '../../internal/business/pip.dart';
import '../../utils/zegocloud_token.dart';
import '../../zego_call_manager.dart';
import '../../zego_sdk_key_center.dart';
import 'call_container.dart';

class CallingPage extends StatefulWidget {
  const CallingPage({required this.callData, super.key});

  final ZegoCallData callData;

  @override
  State<CallingPage> createState() => _CallingPageState();
}

class _CallingPageState extends State<CallingPage> {
  List<StreamSubscription<dynamic>?> subscriptions = [];
  List<String> streamIDList = [];
  Timer? _durationTimer;
  Duration _elapsed = Duration.zero;

@override
void initState() {
  super.initState();

  subscriptions.addAll([
    ZEGOSDKManager()
        .expressService
        .streamListUpdateStreamCtrl
        .stream
        .listen(onStreamListUpdate),
    ZegoCallManager()
        .onCallStartStreamCtrl
        .stream
        .listen((_) => _startDurationTimer()),
  ]);

  // Call may already be connected before this page mounted
  if (ZegoCallManager().isCallStart) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _startDurationTimer());
  }

  String? token;
  if (kIsWeb) {
    token = ZegoTokenUtils.generateToken(
      SDKKeyCenter.appID,
      SDKKeyCenter.serverSecret,
      ZEGOSDKManager().currentUser!.userID,
    );
  }
  final roomID = widget.callData.callID;
  
  // FIX: Use HighQualityChatroom for BOTH platforms (same as audio room)
  final scenario = widget.callData.callType == VOICE_Call
      ? ZegoScenario.HighQualityChatroom  // ← CHANGED
      : ZegoScenario.StandardVideoCall;
      
  ZEGOSDKManager()
      .loginRoom(
    roomID,
    scenario,
    token: token,
  )
      .then((value) async {  // ← Make this async
    if (value.errorCode == 0) {
      // FIX: Force speaker route FIRST (before anything else)
      if (!kIsWeb) {
        ZEGOSDKManager().expressService.setAudioRouteToSpeaker(true);
      }
      
      // Then enable microphone
      ZEGOSDKManager().expressService.turnMicrophoneOn(true);
      
      // Camera handling
      if (kIsWeb || widget.callData.callType == VOICE_Call) {
        ZEGOSDKManager().expressService.turnCameraOn(false);
      } else {
        ZEGOSDKManager().expressService.turnCameraOn(true);
        ZEGOSDKManager().expressService.startPreview();
      }
      
      // Start publishing
      ZEGOSDKManager()
          .expressService
          .startPublishingStream(ZegoCallManager().getMainStreamID());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'join room fail: ${value.errorCode},${value.extendedData}'),
        ),
      );
    }
  });
}

  void _startDurationTimer() {
    _durationTimer?.cancel();
    final startTime = ZegoCallManager().callStartTime;
    _elapsed = startTime != null ? DateTime.now().difference(startTime) : Duration.zero;
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
    });
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    for (final subscription in subscriptions) {
      subscription?.cancel();
    }
    ZegoCallManager().quitCall();
    streamIDList.forEach(ZEGOSDKManager().expressService.stopPlayingStream);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) ZegoCallManager().quitCall();
      },
      child: Scaffold(
        body: SafeArea(
          child: kIsWeb
              ? Stack(
                  children: [
                    const CallContainer(),
                    topBar(),
                    bottomBar(),
                  ],
                )
              : PiPSwitcher(
                  floating: ZegoPIPController().floating,
                  childWhenDisabled: Stack(
                    children: [
                      const CallContainer(),
                      topBar(),
                      bottomBar(),
                    ],
                  ),
                  childWhenEnabled: const CallContainer(),
                ),
        ),
      ),
    );
  }

  Widget topBar() {
    return LayoutBuilder(builder: (context, containers) {
      return Padding(
        padding: const EdgeInsets.only(left: 0, right: 0, top: 10),
        child: topView(),
      );
    });
  }

  Widget bottomBar() {
    return LayoutBuilder(builder: (context, containers) {
      return Padding(
        padding:
            EdgeInsets.only(left: 0, right: 0, top: containers.maxHeight - 70),
        child: buttonView(),
      );
    });
  }

  Widget topView() {
    final minutes = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_durationTimer != null)
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              '$minutes:$seconds',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
            ),
          )
        else
          const SizedBox.shrink(),
        if (!kIsWeb) pipButton(),
      ],
    );
  }

  Widget buttonView() {
    if (widget.callData.callType == VOICE_Call) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          toggleMicButton(),
          endCallButton(),
          speakerButton(),
          inviteUserButton()
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          toggleMicButton(),
          toggleCameraButton(),
          endCallButton(),
          speakerButton(),
          switchCameraButton(),
          inviteUserButton()
        ],
      );
    }
  }

  Widget backgroundImage() {
    return Image.asset(
      'assets/icons/bg.png',
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.fill,
    );
  }

  Widget endCallButton() {
    return SizedBox(
      width: 50,
      height: 50,
      child: ZegoCancelButton(
        onPressed: () {
          ZegoCallManager().quitCall();
        },
      ),
    );
  }

  Widget pipButton() {
    return const SizedBox(
      width: 50,
      height: 50,
      child: ZegoPIPButton(),
    );
  }

  Widget toggleMicButton() {
    return const SizedBox(
      width: 50,
      height: 50,
      child: ZegoToggleMicrophoneButton(),
    );
  }

  Widget toggleCameraButton() {
    return const SizedBox(
      width: 50,
      height: 50,
      child: ZegoToggleCameraButton(),
    );
  }

  Widget switchCameraButton() {
    return const SizedBox(
      width: 50,
      height: 50,
      child: ZegoSwitchCameraButton(),
    );
  }

  Widget speakerButton() {
    return const SizedBox(
      width: 50,
      height: 50,
      child: ZegoSpeakerButton(),
    );
  }

  Widget inviteUserButton() {
    return const SizedBox(
      width: 50,
      height: 50,
      child: ZegoCallAddUserButton(),
    );
  }

  void onStreamListUpdate(ZegoRoomStreamListUpdateEvent event) {
    for (final stream in event.streamList) {
      if (event.updateType == ZegoUpdateType.Add) {
        streamIDList.add(stream.streamID);
        // On web, express_service's onRoomStreamUpdate already calls startPlayingStream
        // (unawaited) before firing this event. Calling it again concurrently causes the
        // web SDK to restart the stream mid-setup, permanently breaking audio playback.
        if (!kIsWeb) {
          ZEGOSDKManager().expressService.startPlayingStream(stream.streamID);
        }
      } else {
        streamIDList.remove(stream.streamID);
        ZEGOSDKManager().expressService.stopPlayingStream(stream.streamID);
      }
    }
  }
}
