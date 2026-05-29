import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class NetworkAwareWrapper extends StatefulWidget {
  final Widget child;

  const NetworkAwareWrapper({super.key, required this.child});

  @override
  State<NetworkAwareWrapper> createState() => _NetworkAwareWrapperState();
}

class _NetworkAwareWrapperState extends State<NetworkAwareWrapper>
    with SingleTickerProviderStateMixin {
  late StreamSubscription<List<ConnectivityResult>> _subscription;
  bool _isOffline = false;
  late AnimationController _animController;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _subscription = Connectivity()
        .onConnectivityChanged
        .listen(_onConnectivityChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Connectivity().checkConnectivity().then((r) {
        if (mounted) _onConnectivityChanged(r);
      });
    });
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final offline = results.isEmpty ||
        results.every((r) => r == ConnectivityResult.none);

    if (offline == _isOffline) return;

    setState(() => _isOffline = offline);

    if (offline) {
      _animController.forward();
    } else {
      // Show "back online" briefly then hide
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _animController.reverse();
      });
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SlideTransition(
            position: _slideAnim,
            child: _isOffline ? _offlineBanner() : _onlineBanner(),
          ),
        ),
      ],
    );
  }

  Widget _offlineBanner() {
    return Material(
      color: Colors.transparent,
      child: Container(
        color: const Color(0xFFB00020),
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          bottom: 10,
          left: 16,
          right: 16,
        ),
        child: const Row(
          children: [
            Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'No internet connection. Please check your network.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _onlineBanner() {
    return Material(
      color: Colors.transparent,
      child: Container(
        color: const Color(0xFF2E7D32),
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          bottom: 10,
          left: 16,
          right: 16,
        ),
        child: const Row(
          children: [
            Icon(Icons.wifi_rounded, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text(
              'Back online',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
