import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PhoneVerifyScreen extends StatefulWidget {
  const PhoneVerifyScreen({super.key});

  @override
  State<PhoneVerifyScreen> createState() => _PhoneVerifyScreenState();
}

class _PhoneVerifyScreenState extends State<PhoneVerifyScreen> {
  final _phone = TextEditingController(text: '+880');
  final _code = TextEditingController();
  String? _verificationId;
  bool _busy = false;
  String? _message;

  bool get _verified =>
      (FirebaseAuth.instance.currentUser?.phoneNumber ?? '').isNotEmpty;

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: _phone.text.trim(),
      verificationCompleted: (cred) => _link(cred),
      verificationFailed: (e) {
        if (!mounted) return;
        setState(() {
          _busy = false;
          _message = e.message ?? e.code;
        });
      },
      codeSent: (id, _) {
        if (!mounted) return;
        setState(() {
          _verificationId = id;
          _busy = false;
          _message = 'Code sent. Enter it below.';
        });
      },
      codeAutoRetrievalTimeout: (id) => _verificationId = id,
    );
  }

  Future<void> _confirm() async {
    if (_verificationId == null) return;
    setState(() => _busy = true);
    final cred = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: _code.text.trim(),
    );
    await _link(cred);
  }

  Future<void> _link(PhoneAuthCredential cred) async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      await user.linkWithCredential(cred);
      await user.reload();
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'phone': FirebaseAuth.instance.currentUser?.phoneNumber,
      }, SetOptions(merge: true));
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = 'Phone number verified';
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = e.message ?? e.code;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify phone number')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _verified
            ? Center(
                child: Text(
                  'Verified: ${FirebaseAuth.instance.currentUser?.phoneNumber}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              )
            : ListView(
                children: [
                  TextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone (with country code)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _busy ? null : _sendCode,
                    child: const Text('Send code'),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _code,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '6-digit code',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: (_busy || _verificationId == null)
                        ? null
                        : _confirm,
                    child: const Text('Verify'),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 16),
                    Text(_message!, textAlign: TextAlign.center),
                  ],
                ],
              ),
      ),
    );
  }
}
