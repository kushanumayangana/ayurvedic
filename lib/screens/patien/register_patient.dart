import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../home/home.dart';

class RegisterPatient extends StatefulWidget {
  const RegisterPatient({super.key});

  @override
  State<RegisterPatient> createState() => _RegisterPatientState();
}

class _RegisterPatientState extends State<RegisterPatient> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = false;
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Enter your name';
    if (name.length < 2) return 'Name must be at least 2 characters';
    if (name.length > 80) return 'Name must be 80 characters or fewer';
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Enter your email address';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Enter your password';
    if (!_isLogin && password.length < 8) {
      return 'Use at least 8 characters';
    }
    if (!_isLogin &&
        (!RegExp(r'[A-Za-z]').hasMatch(password) ||
            !RegExp(r'[0-9]').hasMatch(password))) {
      return 'Include at least one letter and one number';
    }
    return null;
  }

  Future<void> _registerPatient() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    User? createdUser;

    try {
      final email = _emailController.text.trim().toLowerCase();
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email,
            password: _passwordController.text,
          );
      final user = credential.user;
      if (user == null) {
        throw StateError('Account creation did not return a user.');
      }
      createdUser = user;

      final name = _nameController.text.trim();
      await user.updateDisplayName(name);
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(user.uid)
          .set({
            'name': name,
            'email': user.email ?? email,
            'role': 'patient',
            'createdAt': FieldValue.serverTimestamp(),
          });
      await user.sendEmailVerification();
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      setState(() => _isLogin = true);
      _showMessage('Verification link sent. Verify your email, then sign in.');
    } on FirebaseAuthException catch (error) {
      if (createdUser != null &&
          FirebaseAuth.instance.currentUser?.uid == createdUser.uid) {
        await FirebaseAuth.instance.signOut();
      }
      if (mounted) _showMessage(_authErrorMessage(error));
    } catch (error) {
      if (createdUser != null &&
          FirebaseAuth.instance.currentUser?.uid == createdUser.uid) {
        await FirebaseAuth.instance.signOut();
      }
      if (mounted) _showMessage('Could not create your account: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginPatient() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim().toLowerCase(),
        password: _passwordController.text,
      );
      await credential.user?.reload();
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw StateError('Sign in did not return a user.');
      }
      if (!user.emailVerified) {
        try {
          await user.sendEmailVerification();
        } finally {
          await FirebaseAuth.instance.signOut();
        }
        if (mounted) {
          _showMessage(
            'Your email is not verified yet. A new verification link was sent.',
          );
        }
        return;
      }

      final profile = await FirebaseFirestore.instance
          .collection('patients')
          .doc(user.uid)
          .get();
      if (!profile.exists || profile.data()?['role'] != 'patient') {
        await FirebaseAuth.instance.signOut();
        throw StateError('Patient profile not found. Please register again.');
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (_) => const HomePage(role: 'patient'),
        ),
      );
    } on FirebaseAuthException catch (error) {
      if (mounted) _showMessage(_authErrorMessage(error));
    } catch (error) {
      if (mounted) {
        _showMessage(error.toString().replaceFirst('Bad state: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _authErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'An account already exists for this email. Please sign in.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      case 'weak-password':
        return 'Choose a stronger password.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _formKey.currentState?.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    const forest = Color(0xFF174C3C);
    const green = Color(0xFF2F8062);
    const canvas = Color(0xFFF5F8F5);

    return Scaffold(
      backgroundColor: canvas,
      appBar: AppBar(
        backgroundColor: canvas,
        foregroundColor: forest,
        elevation: 0,
        title: const Text('Patient account'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE1F0E8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.spa_outlined,
                      color: forest,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _isLogin ? 'Welcome back' : 'Your wellness starts here',
                    style: const TextStyle(
                      color: forest,
                      fontSize: 29,
                      height: 1.15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isLogin
                        ? 'Sign in to manage appointments, orders, and your profile.'
                        : 'Create an account to connect with doctors, shop, and learn.',
                    style: TextStyle(
                      color: Colors.blueGrey.shade600,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 26),
                  Card(
                    color: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (!_isLogin) ...[
                              TextFormField(
                                controller: _nameController,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                validator: _validateName,
                                decoration: _inputDecoration(
                                  'Full name',
                                  Icons.person_outline,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autocorrect: false,
                              validator: _validateEmail,
                              decoration: _inputDecoration(
                                'Email address',
                                Icons.alternate_email,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              validator: _validatePassword,
                              onFieldSubmitted: (_) => _submit(),
                              decoration:
                                  _inputDecoration(
                                    'Password',
                                    Icons.lock_outline,
                                  ).copyWith(
                                    suffixIcon: IconButton(
                                      tooltip: _obscurePassword
                                          ? 'Show password'
                                          : 'Hide password',
                                      onPressed: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                    ),
                                  ),
                            ),
                            if (!_isLogin) ...[
                              const SizedBox(height: 9),
                              Text(
                                'Use at least 8 characters, including a letter and a number.',
                                style: TextStyle(
                                  color: Colors.blueGrey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 54,
                              child: FilledButton(
                                onPressed: _loading ? null : _submit,
                                style: FilledButton.styleFrom(
                                  backgroundColor: green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                child: _loading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        _isLogin
                                            ? 'Sign in'
                                            : 'Create patient account',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: TextButton(
                                onPressed: _loading ? null : _toggleMode,
                                child: Text(
                                  _isLogin
                                      ? 'New to AyurvedaCare? Create account'
                                      : 'Already have an account? Sign in',
                                  style: const TextStyle(color: forest),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        size: 16,
                        color: green,
                      ),
                      SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          'Email verification is required to access patient services.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.blueGrey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xFFF7F9F7),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFF2F8062), width: 1.5),
      ),
    );
  }

  void _submit() {
    if (_loading) return;
    if (_isLogin) {
      _loginPatient();
    } else {
      _registerPatient();
    }
  }
}
