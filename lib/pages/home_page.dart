import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app_globals.dart';
import '../pages/login_page.dart';
import 'call/call.dart';
import 'contact_us_page.dart';
import 'privacy_policy_page.dart';
import 'profile_page.dart';
import 'recent_calls_page.dart';
import 'terms_page.dart';

part 'entry_call.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _navy = Color(0xFF0D1B2A);
  static const _bg = Color(0xFFF2F3F5);

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _callHistoryStream;
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _execDocStream;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    _callHistoryStream = FirebaseFirestore.instance
        .collection('executives')
        .doc(uid)
        .collection('call_history')
        .snapshots();

    _execDocStream = FirebaseFirestore.instance
        .collection('executives')
        .doc(uid)
        .snapshots();
  }

  // ── Helpers ───────────────────────────────────────────────

  bool _isMissed(Map<String, dynamic> c) {
    final s = (c['status'] as String? ?? '').toLowerCase();
    return s == 'timed_out' || s == 'rejected' || s == 'missed';
  }

  String _statusLabel(Map<String, dynamic> c) {
    final s = (c['status'] as String? ?? '').toLowerCase();
    if (s == 'timed_out' || s == 'rejected' || s == 'missed') return 'Missed';
    if (s == 'completed' || s == 'answered' || s == 'accepted') return 'Completed';
    return 'Incoming';
  }

  Color _statusColor(Map<String, dynamic> c) {
    final s = _statusLabel(c);
    if (s == 'Missed') return Colors.red;
    if (s == 'Completed') return Colors.green;
    return Colors.blue;
  }

  String _formatDateTime(dynamic ts) {
    if (ts == null) return '';
    final dt = (ts as Timestamp).toDate().toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dtDate = DateTime(dt.year, dt.month, dt.day);
    String dateStr;
    if (dtDate == today) {
      dateStr = 'Today';
    } else if (dtDate == today.subtract(const Duration(days: 1))) {
      dateStr = 'Yesterday';
    } else {
      dateStr = '${dt.day}/${dt.month}/${dt.year}';
    }
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final min = dt.minute.toString().padLeft(2, '0');
    final amPm = dt.hour < 12 ? 'AM' : 'PM';
    return '$dateStr, $h:$min $amPm';
  }

  String _getDuration(String callId, List<Map<String, dynamic>> history) {
    try {
      final match = history.firstWhere((c) => c['callID'] == callId);
      final s = (match['durationSeconds'] as int?) ?? 0;
      if (s == 0) return '--';
      return '${s ~/ 60}m ${(s % 60).toString().padLeft(2, '0')}s';
    } catch (_) {
      return '--';
    }
  }

  String _talkTimeLabel(int totalSec) {
    if (totalSec == 0) return '0m';
    final h = totalSec ~/ 3600;
    final m = (totalSec % 3600) ~/ 60;
    final s = totalSec % 60;
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    if (m > 0) return '${m}m ${s.toString().padLeft(2, '0')}s';
    return '${s}s';
  }

  Future<void> _toggleAvailability(bool isOnline) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    await FirebaseFirestore.instance
        .collection('executives')
        .doc(uid)
        .update({'availability': isOnline ? 'online' : 'offline'});
  }

  Future<void> _logout() async {
    try {
      await ZEGOSDKManager().disconnectUser();
    } catch (_) {}
    await FirebaseAuth.instance.signOut();
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage(title: 'Login Page')),
      (_) => false,
    );
  }

  String get _initials {
    final name = ZEGOSDKManager().currentUser?.userName ?? '';
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _bg,
      drawer: _buildDrawer(context),
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            Expanded(
              child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: _execDocStream,
                builder: (context, execSnap) {
                  final data = execSnap.data?.data() ?? {};
                  final callHistoryArray =
                      ((data['callHistory'] as List<dynamic>?) ?? [])
                          .cast<Map<String, dynamic>>();
                  final totalDuration = callHistoryArray.fold<int>(
                      0, (acc, c) => acc + ((c['durationSeconds'] as int?) ?? 0));
                  final availability =
                      (data['availability'] as String? ?? 'online').toLowerCase();
                  final isOnline = availability == 'online';

                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _callHistoryStream,
                    builder: (context, histSnap) {
                      final allCalls =
                          (histSnap.data?.docs.map((d) => d.data()).toList() ?? [])
                            ..sort((a, b) {
                              final ta = a['date_time'] as Timestamp?;
                              final tb = b['date_time'] as Timestamp?;
                              if (ta == null && tb == null) return 0;
                              if (ta == null) return 1;
                              if (tb == null) return -1;
                              return tb.compareTo(ta);
                            });

                      final totalCalls = allCalls.length;
                      final missedCalls = allCalls.where(_isMissed).length;
                      final recentCalls = allCalls.take(6).toList();
                      final loading =
                          histSnap.connectionState == ConnectionState.waiting;

                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            _statsCard(
                              totalCalls,
                              missedCalls,
                              _talkTimeLabel(totalDuration),
                              isOnline,
                              loading,
                            ),
                            const SizedBox(height: 24),
                            _recentCallsSection(
                                recentCalls, callHistoryArray, loading),
                            const SizedBox(height: 30),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Widgets ───────────────────────────────────────────────

  Widget _topBar() {
    final name = ZEGOSDKManager().currentUser?.userName ?? '';
    final userID = ZEGOSDKManager().currentUser?.userID ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.menu_rounded, color: _navy, size: 26),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CallFrnd',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _navy,
                ),
              ),
              if (name.isNotEmpty)
                Text(
                  '$name · #$userID',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      color: _navy,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    ZEGOSDKManager().currentUser?.userName ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _navy,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFFDEE1E6), height: 1),
            const SizedBox(height: 8),
            _drawerItem(
              context,
              icon: Icons.home_outlined,
              label: 'Home',
              onTap: () => Navigator.pop(context),
            ),
            _drawerItem(
              context,
              icon: Icons.call_outlined,
              label: 'Recent Calls',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RecentCallsPage()),
                );
              },
            ),
            _drawerItem(
              context,
              icon: Icons.description_outlined,
              label: 'Terms & Conditions',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TermsPage()),
                );
              },
            ),
            _drawerItem(
              context,
              icon: Icons.privacy_tip_outlined,
              label: 'Privacy Policy',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const PrivacyPolicyPage()),
                );
              },
            ),
            _drawerItem(
              context,
              icon: Icons.headset_mic_outlined,
              label: 'Contact Us',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ContactUsPage()),
                );
              },
            ),
            _drawerItem(
              context,
              icon: Icons.person_outline_rounded,
              label: 'Profile',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                );
              },
            ),
            const Spacer(),
            const Divider(color: Color(0xFFDEE1E6), height: 1),
            _drawerItem(
              context,
              icon: Icons.logout_rounded,
              label: 'Sign Out',
              onTap: () async {
                Navigator.pop(context);
                await _logout();
              },
              color: Colors.red,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = _navy,
  }) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      minLeadingWidth: 24,
    );
  }

  Widget _statsCard(
      int total, int missed, String talkTime, bool isOnline, bool loading) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Availability',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isOnline
                                ? const Color(0xFF4CAF50)
                                : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isOnline ? 'Online' : 'Offline',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: isOnline,
                  onChanged: _toggleAvailability,
                  activeColor: const Color(0xFF4CAF50),
                  inactiveThumbColor: Colors.grey,
                  inactiveTrackColor: Colors.white24,
                  activeTrackColor: const Color(0xFF4CAF50).withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: Colors.white12),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('Total Calls', loading ? '-' : '$total'),
              Container(width: 1, height: 36, color: Colors.white24),
              _statItem('Missed', loading ? '-' : '$missed'),
              Container(width: 1, height: 36, color: Colors.white24),
              _statItem('Talk Time', loading ? '-' : talkTime),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _recentCallsSection(
    List<Map<String, dynamic>> calls,
    List<Map<String, dynamic>> history,
    bool loading,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Calls',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: _navy,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RecentCallsPage()),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'View all',
                style: TextStyle(color: _navy, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: CircularProgressIndicator(color: _navy),
            ),
          )
        else if (calls.isEmpty)
          _emptyState()
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: calls.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _callCard(calls[i], history),
          ),
      ],
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _navy.withValues(alpha: 0.07),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.phone_missed_outlined,
                size: 26, color: _navy),
          ),
          const SizedBox(height: 12),
          const Text(
            'No recent calls',
            style: TextStyle(
                color: _navy, fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'Your call history will appear here',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _callCard(
      Map<String, dynamic> call, List<Map<String, dynamic>> history) {
    final callerName = call['caller_name'] as String? ?? 'Unknown';
    final callId = call['call_id'] as String? ?? '';
    final timeStr = _formatDateTime(call['date_time']);
    final missed = _isMissed(call);
    final statusLabel = _statusLabel(call);
    final statusColor = _statusColor(call);
    final duration = missed ? '--' : _getDuration(callId, history);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _navy.withValues(alpha: 0.07),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_rounded, color: _navy, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  callerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: _navy,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  timeStr,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                duration,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _navy,
                ),
              ),
              const SizedBox(height: 5),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '↙ $statusLabel',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget roomIDTextField(TextEditingController controller) {
  return Row(
    children: [
      const Text('RoomID:'),
      const SizedBox(width: 10, height: 20),
      Expanded(
        child: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Please Input RoomID'),
        ),
      ),
    ],
  );
}
