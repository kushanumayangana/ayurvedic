import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../home/home.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController(text: 'uwuict');
  final _secretController = TextEditingController(text: '00000');
  bool _loading = false;
  bool _obscureSecret = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _secretController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final username = _usernameController.text.trim();
    final secret = _secretController.text.trim();

    setState(() => _loading = true);

    try {
      // 1. Direct client-side bypass for uwuict / 00000
      if (username == 'uwuict' && secret == '00000') {
        if (FirebaseAuth.instance.currentUser == null) {
          try {
            await FirebaseAuth.instance.signInAnonymously();
          } catch (_) {
            // If anonymous sign-in is disabled in your live project, 
            // ensure you are logged into your user account in the app first.
          }
        }

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute<void>(
            builder: (_) => const HomePage(role: 'admin'),
          ),
          (route) => false,
        );
        return;
      }

      // 2. Otherwise fall back to live Cloud Function authentication
      final callable = FirebaseFunctions.instanceFor(
        region: 'us-central1',
      ).httpsCallable('adminLogin');

      final response = await callable.call<Map<String, dynamic>>({
        'username': username,
        'secret': secret,
      });

      final token = response.data['customToken']?.toString();
      if (token == null || token.isEmpty) {
        throw StateError('The admin service returned no authentication token');
      }

      await FirebaseAuth.instance.signInWithCustomToken(token);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute<void>(builder: (_) => const HomePage(role: 'admin')),
        (route) => false,
      );
    } on FirebaseFunctionsException catch (error) {
      if (!mounted) return;
      final message = error.code == 'resource-exhausted'
          ? 'Too many attempts. Please wait and try again.'
          : error.code == 'unavailable' || error.code == 'not-found'
          ? 'Admin sign-in is not available. Please contact the app administrator.'
          : 'Admin sign-in failed. Check your credentials and try again.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not sign in: $error')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const navyBlue = Color(0xFF1D2671);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Admin Login'),
        backgroundColor: const Color(0xFFE8EEF0),
        foregroundColor: navyBlue,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              elevation: 2,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.admin_panel_settings_outlined,
                        size: 56,
                        color: navyBlue,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Secure administrator access',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Enter secret name (uwuict) and secret key (00000) to proceed.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.blueGrey),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Secret Name',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter the secret name'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _secretController,
                        obscureText: _obscureSecret,
                        onFieldSubmitted: (_) => _login(),
                        decoration: InputDecoration(
                          labelText: 'Secret Key',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            tooltip: _obscureSecret
                                ? 'Show secret key'
                                : 'Hide secret key',
                            onPressed: () => setState(
                              () => _obscureSecret = !_obscureSecret,
                            ),
                            icon: Icon(
                              _obscureSecret
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter the secret key'
                            : null,
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _loading ? null : _login,
                        icon: _loading
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.login),
                        label: Text(_loading ? 'Signing in...' : 'Sign in'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}