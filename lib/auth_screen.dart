import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

enum UsernameStatus { idle, invalid, checking, available, taken, error }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _usernameRule = RegExp(r'^[a-z0-9_]{3,20}$');

  bool _isLogin = true;
  bool _busy = false;
  String? _error;
  UsernameStatus _status = UsernameStatus.idle;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  // Runs on every keystroke in the username box
  void _onUsernameChanged(String value) {
    _debounce?.cancel();
    final name = value.trim().toLowerCase();

    if (name.isEmpty) {
      setState(() => _status = UsernameStatus.idle);
      return;
    }
    if (!_usernameRule.hasMatch(name)) {
      setState(() => _status = UsernameStatus.invalid);
      return;
    }

    setState(() => _status = UsernameStatus.checking);

    // Wait 500 ms after the last keystroke before asking Firestore
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('usernames')
            .doc(name)
            .get();
        // Ignore the answer if the user kept typing meanwhile
        if (!mounted || _username.text.trim().toLowerCase() != name) return;
        setState(
          () => _status = doc.exists
              ? UsernameStatus.taken
              : UsernameStatus.available,
        );
      } catch (_) {
        if (!mounted) return;
        setState(() => _status = UsernameStatus.error);
      }
    });
  }

  Widget _statusText() {
    switch (_status) {
      case UsernameStatus.idle:
        return const SizedBox.shrink();
      case UsernameStatus.invalid:
        return const Text(
          '3-20 characters: letters, numbers, underscore',
          style: TextStyle(color: Colors.red),
        );
      case UsernameStatus.checking:
        return const Text('Checking...');
      case UsernameStatus.available:
        return const Text(
          'Username is available',
          style: TextStyle(color: Colors.green),
        );
      case UsernameStatus.taken:
        return const Text(
          'Username is already taken',
          style: TextStyle(color: Colors.red),
        );
      case UsernameStatus.error:
        return const Text(
          'Could not check username',
          style: TextStyle(color: Colors.red),
        );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final auth = FirebaseAuth.instance;
      if (_isLogin) {
        await auth.signInWithEmailAndPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      } else {
        final name = _username.text.trim().toLowerCase();
        final cred = await auth.createUserWithEmailAndPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
        final user = cred.user!;

        try {
          // Claim the username and save the profile in one transaction
          final db = FirebaseFirestore.instance;
          await db.runTransaction((tx) async {
            final nameRef = db.collection('usernames').doc(name);
            final snap = await tx.get(nameRef);
            if (snap.exists) throw Exception('taken');
            tx.set(nameRef, {'uid': user.uid});
            tx.set(db.collection('users').doc(user.uid), {
              'username': name,
              'email': user.email,
              'createdAt': FieldValue.serverTimestamp(),
            });
          });
        } catch (_) {
          // Someone took the name a moment ago: undo the account
          await user.delete();
          if (mounted) {
            setState(() {
              _status = UsernameStatus.taken;
              _error = 'That username was just taken. Choose another.';
            });
          }
          return;
        }

        await user.sendEmailVerification();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = e.message ?? e.code);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'CookNest',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 24),
                  if (!_isLogin) ...[
                    TextFormField(
                      controller: _username,
                      onChanged: _onUsernameChanged,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => _status == UsernameStatus.available
                          ? null
                          : 'Choose an available username',
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4, left: 4),
                        child: _statusText(),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || !v.contains('@'))
                        ? 'Enter a valid email'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.length < 6)
                        ? 'At least 6 characters'
                        : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(_isLogin ? 'Log in' : 'Sign up'),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _isLogin = !_isLogin;
                      _error = null;
                    }),
                    child: Text(
                      _isLogin
                          ? 'New here? Create an account'
                          : 'Already have an account? Log in',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
