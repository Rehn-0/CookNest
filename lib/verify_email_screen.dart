import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  String? _message;

  Future<void> _resend() async {
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      setState(() => _message = 'Verification email sent again.');
    } on FirebaseAuthException catch (e) {
      setState(() => _message = e.message ?? e.code);
    }
  }

  Future<void> _check() async {
    await FirebaseAuth.instance.currentUser?.reload();
    final verified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;
    if (!verified && mounted) {
      setState(
        () => _message = 'Not verified yet. Open the link in your email first.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Verify your email')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mark_email_unread_outlined, size: 64),
            const SizedBox(height: 16),
            Text(
              'We sent a verification link to\n$email',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Check your spam folder if you cannot find it.',
              textAlign: TextAlign.center,
            ),
            if (_message != null) ...[
              const SizedBox(height: 12),
              Text(_message!, textAlign: TextAlign.center),
            ],
            const SizedBox(height: 24),
            FilledButton(onPressed: _check, child: const Text("I've verified")),
            TextButton(onPressed: _resend, child: const Text('Resend email')),
            TextButton(
              onPressed: () => FirebaseAuth.instance.signOut(),
              child: const Text('Use a different account'),
            ),
          ],
        ),
      ),
    );
  }
}
