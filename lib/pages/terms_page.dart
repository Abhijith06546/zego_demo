import 'package:flutter/material.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

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
                        'Terms & Conditions',
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

1. AGREEMENT TO TERMS

This legal agreement is an online document according to the Indian Information Technology Act, 2000, and its rules, including any updates made to laws about electronic records by this act. This electronic record is made by a computer and does not need any handwritten or digital signatures.

By accessing or using CallFrnd, you agree to be bound by these Terms and Conditions. If you do not agree to any of these terms, please do not use our platform.

2. ELIGIBILITY

You must be at least 18 years of age to use this service. By using CallFrnd, you represent and warrant that you are at least 18 years old and have the legal capacity to enter into this agreement.

3. USER ACCOUNTS

You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account. You agree to notify us immediately of any unauthorized use of your account.

4. SERVICES

CallFrnd provides a platform that enables voice and video calling between users and executives. The platform is provided "as is" and we make no guarantees about availability, uptime, or uninterrupted service.

5. ACCEPTABLE USE

You agree not to use the platform for any unlawful purposes, to harass, abuse, or harm another person, to impersonate any person or entity, or to engage in any fraudulent activity.

6. INTELLECTUAL PROPERTY

All content, features, and functionality on CallFrnd, including but not limited to text, graphics, logos, and software, are the exclusive property of CallFrnd and are protected by applicable intellectual property laws.

7. PRIVACY

Your use of CallFrnd is also governed by our Privacy Policy, which is incorporated into these Terms by reference.

8. LIMITATION OF LIABILITY

To the fullest extent permitted by law, CallFrnd shall not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use of or inability to use the service.

9. TERMINATION

We reserve the right to terminate or suspend your account and access to the service at our sole discretion, without notice, for conduct that we believe violates these Terms or is harmful to other users, us, or third parties.

10. GOVERNING LAW

These Terms shall be governed by and construed in accordance with the laws of India, including the Information Technology Act, 2000, the Information Technology (Intermediaries Guidelines) Rules, 2011, and the Information Technology (Reasonable Security Practices and Procedures and Sensitive Personal Data or Information) Rules, 2011.

11. CHANGES TO TERMS

We reserve the right to modify these terms at any time. We will notify users of significant changes via email or through the app. Your continued use of CallFrnd after such modifications constitutes your acceptance of the updated terms.

12. CONTACT US

If you have any questions about these Terms, please contact us at info@califrnd.in or +91 9443882681.''',
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
