import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  static const _navy = Color(0xFF0D1B2A);
  static const _bg = Color(0xFFF2F3F5);

  @override
  Widget build(BuildContext context) {
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
                        'Privacy Policy',
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Text(
                    '''
Last Updated: January 1, 2025

INTRODUCTION

CallFrnd ("we", "our", or "us") is committed to protecting your personal information. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our platform. We are committed to ensuring your privacy rights in accordance with applicable Indian and international data protection laws.

DATA WE COLLECT

We collect information in the following ways:

a. Information you provide directly:
   — Full name, email address, phone number
   — City, age, and gender
   — Account credentials (password stored in encrypted form)
   — Profile information and preferences

b. Information collected automatically:
   — Call records including duration, timestamp, and participants
   — Device information (device type, operating system)
   — Log data (IP address, access times, pages viewed)
   — Usage patterns and interaction data

c. Information from third parties:
   — Authentication data from Firebase Authentication
   — Any information you provide through linked services

HOW WE USE YOUR DATA

We use the collected information to:
   — Provide, maintain, and improve our services
   — Process and facilitate voice and video calls
   — Send service-related communications
   — Monitor and analyze usage patterns to improve user experience
   — Detect, investigate, and prevent fraudulent or illegal activities
   — Comply with legal obligations under Indian law

DATA SHARING AND DISCLOSURE

We do not sell your personal data to third parties. We may share your information with:
   — Service providers who assist in operating our platform (Firebase, ZEGOCLOUD)
   — Law enforcement agencies when required by applicable law
   — Other parties with your explicit consent

YOUR RIGHTS UNDER GDPR AND INDIAN IT ACT

You have the right to:
   — Access the personal data we hold about you
   — Request correction of inaccurate data
   — Request deletion of your data ("right to be forgotten")
   — Object to or restrict processing of your data
   — Data portability — receive your data in a structured format

To exercise any of these rights, contact us at info@califrnd.in.

DATA RETENTION

We retain your personal data for as long as your account is active or as needed to provide services. Call records are retained for a period of 12 months from the date of the call.

DATA SECURITY

We implement industry-standard security measures including encryption, secure servers, and access controls to protect your personal information. However, no method of transmission over the internet is 100% secure.

CHILDREN'S PRIVACY

Our service is not directed to individuals under the age of 18. We do not knowingly collect personal information from minors.

CHANGES TO THIS POLICY

We may update this Privacy Policy periodically. We will notify you of significant changes through the app or via email. Continued use of the platform after changes constitutes acceptance of the updated policy.

CONTACT US

For any privacy-related queries or to exercise your data rights:
Email: info@califrnd.in
Phone: +91 9443882681
''',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF444444),
                      height: 1.7,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
