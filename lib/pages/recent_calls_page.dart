import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RecentCallsPage extends StatefulWidget {
  const RecentCallsPage({super.key});

  @override
  State<RecentCallsPage> createState() => _RecentCallsPageState();
}

class _RecentCallsPageState extends State<RecentCallsPage> {
  static const _navy = Color(0xFF0D1B2A);
  static const _bg = Color(0xFFF2F3F5);

  String _filter = 'All';
  final _filters = ['All', 'Completed', 'Missed'];

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stream;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _stream = FirebaseFirestore.instance
        .collection('executives')
        .doc(uid)
        .collection('call_history')
        .snapshots();
  }

  bool _isMissed(Map<String, dynamic> c) {
    final s = (c['status'] as String? ?? '').toLowerCase();
    return s == 'timed_out' || s == 'rejected' || s == 'missed';
  }

  bool _isCompleted(Map<String, dynamic> c) {
    final s = (c['status'] as String? ?? '').toLowerCase();
    return s == 'completed' || s == 'answered' || s == 'accepted';
  }

  String _statusLabel(Map<String, dynamic> c) {
    if (_isMissed(c)) return 'Missed';
    if (_isCompleted(c)) return 'Completed';
    return 'Incoming';
  }

  Color _statusColor(Map<String, dynamic> c) {
    if (_isMissed(c)) return Colors.red;
    if (_isCompleted(c)) return Colors.green;
    return Colors.blue;
  }

  IconData _statusIcon(Map<String, dynamic> c) {
    if (_isMissed(c)) return Icons.call_missed_rounded;
    if (_isCompleted(c)) return Icons.call_made_rounded;
    return Icons.call_received_rounded;
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

  List<Map<String, dynamic>> _applyFilter(List<Map<String, dynamic>> all) {
    switch (_filter) {
      case 'Completed':
        return all.where(_isCompleted).toList();
      case 'Missed':
        return all.where(_isMissed).toList();
      default:
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: _navy, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Recent calls',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _navy,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: _filters.map((f) {
                  final selected = _filter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _filter = f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? _navy : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected ? _navy : const Color(0xFFDEE1E6),
                          ),
                        ),
                        child: Text(
                          f,
                          style: TextStyle(
                            color:
                                selected ? Colors.white : const Color(0xFF555555),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _stream,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: _navy),
                    );
                  }
                  final all =
                      (snap.data?.docs.map((d) => d.data()).toList() ?? [])
                        ..sort((a, b) {
                          final ta = a['date_time'] as Timestamp?;
                          final tb = b['date_time'] as Timestamp?;
                          if (ta == null && tb == null) return 0;
                          if (ta == null) return 1;
                          if (tb == null) return -1;
                          return tb.compareTo(ta);
                        });
                  final calls = _applyFilter(all);

                  if (calls.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: _navy.withValues(alpha: 0.07),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.phone_missed_outlined,
                                size: 28, color: _navy),
                          ),
                          const SizedBox(height: 14),
                          const Text('No calls found',
                              style: TextStyle(
                                  color: _navy,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          const Text('Your call history will appear here',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: calls.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _callCard(calls[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _callCard(Map<String, dynamic> call) {
    final callerName = call['caller_name'] as String? ?? 'Unknown';
    final timeStr = _formatDateTime(call['date_time']);
    final statusLabel = _statusLabel(call);
    final statusColor = _statusColor(call);
    final statusIcon = _statusIcon(call);
    final durationSec = call['durationSeconds'] as int? ?? 0;
    final durationStr = durationSec == 0
        ? '--'
        : '${durationSec ~/ 60}m ${(durationSec % 60).toString().padLeft(2, '0')}s';

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
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _navy.withValues(alpha: 0.07),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_rounded, color: _navy, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(callerName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: _navy)),
                const SizedBox(height: 3),
                Text(timeStr,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(durationStr,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _navy)),
              const SizedBox(height: 5),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
