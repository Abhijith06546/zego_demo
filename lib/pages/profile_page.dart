import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app_globals.dart';
import 'call/call.dart';
import 'login_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const _navy = Color(0xFF0D1B2A);
  static const _bg = Color(0xFFF2F3F5);
  static const _borderColor = Color(0xFFDEE1E6);

  Future<void> _logout(BuildContext context) async {
    try {
      await ZEGOSDKManager().disconnectUser();
    } catch (_) {}
    await FirebaseAuth.instance.signOut();
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage(title: 'Login Page')),
      (_) => false,
    );
  }

  void _editField(BuildContext context, String field, String label,
      String currentValue) {
    final ctrl = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit $label',
            style: const TextStyle(color: _navy, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _navy, width: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _navy,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            onPressed: () async {
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid != null && ctrl.text.trim().isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('executives')
                    .doc(uid)
                    .update({field: ctrl.text.trim()});
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                        'Profile',
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
            Expanded(
              child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('executives')
                    .doc(uid)
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: _navy),
                    );
                  }
                  final data = snap.data?.data() ?? {};
                  final firstName = data['firstName'] as String? ?? '';
                  final lastName = data['lastName'] as String? ?? '';
                  final fullName = '$firstName $lastName'.trim();
                  final email = data['email'] as String? ?? '';
                  final phone = data['phone'] as String? ?? '';
                  final city = data['city'] as String? ?? '';
                  final age = data['age']?.toString() ?? '';
                  final gender = data['gender'] as String? ?? '';
                  final availability =
                      (data['availability'] as String? ?? 'online')
                          .toLowerCase();
                  final isOnline = availability == 'online';

                  final initials = () {
                    final parts = fullName.trim().split(' ');
                    if (parts.isEmpty || parts[0].isEmpty) return '?';
                    if (parts.length == 1) return parts[0][0].toUpperCase();
                    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
                  }();

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                    child: Column(
                      children: [
                        _avatarSection(initials, fullName, isOnline),
                        const SizedBox(height: 20),
                        _infoCard(context, data, fullName, email, phone, city,
                            age, gender),
                        const SizedBox(height: 20),
                        _logoutButton(context),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarSection(String initials, String name, bool isOnline) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: _navy,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _navy.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _navy,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: isOnline
                ? const Color(0xFF4CAF50).withValues(alpha: 0.12)
                : Colors.grey.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
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
                style: TextStyle(
                  color: isOnline
                      ? const Color(0xFF4CAF50)
                      : Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoCard(
    BuildContext context,
    Map<String, dynamic> data,
    String fullName,
    String email,
    String phone,
    String city,
    String age,
    String gender,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 16, 12),
            child: Row(
              children: [
                Text(
                  'PERSONAL INFO',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF888888),
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
          const Divider(color: _borderColor, height: 1),
          _infoTile(
            context,
            icon: Icons.person_outline_rounded,
            label: 'FULL NAME',
            value: fullName,
            onTap: () {
              final parts = fullName.split(' ');
              final first = parts.isNotEmpty ? parts[0] : '';
              _editField(context, 'firstName', 'First Name', first);
            },
          ),
          _divider(),
          _infoTile(
            context,
            icon: Icons.email_outlined,
            label: 'EMAIL',
            value: email,
            onTap: () => _editField(context, 'email', 'Email', email),
          ),
          _divider(),
          _infoTile(
            context,
            icon: Icons.phone_outlined,
            label: 'PHONE',
            value: phone,
            onTap: () => _editField(context, 'phone', 'Phone', phone),
          ),
          _divider(),
          _infoTile(
            context,
            icon: Icons.location_on_outlined,
            label: 'CITY',
            value: city,
            onTap: () => _editField(context, 'city', 'City', city),
          ),
          _divider(),
          _infoTile(
            context,
            icon: Icons.cake_outlined,
            label: 'AGE',
            value: age,
            onTap: () => _editField(context, 'age', 'Age', age),
          ),
          _divider(),
          _infoTile(
            context,
            icon: Icons.wc_outlined,
            label: 'GENDER',
            value: gender,
            onTap: () => _editField(context, 'gender', 'Gender', gender),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _infoTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        bottom: isLast ? const Radius.circular(20) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF888888),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value.isEmpty ? '—' : value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _navy,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFFBBBBBB), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _divider() =>
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Divider(color: _borderColor, height: 1),
      );

  Widget _logoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () => _logout(context),
        icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 18),
        label: const Text(
          'Logout',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _navy,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
