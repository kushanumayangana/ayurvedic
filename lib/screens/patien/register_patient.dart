import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../home/home.dart';

class RegisterPatient extends StatefulWidget {
  const RegisterPatient({Key? key}) : super(key: key);

  @override
  State<RegisterPatient> createState() => _RegisterPatientState();
}

class _RegisterPatientState extends State<RegisterPatient> {
  bool isLogin = false;
  bool loading = false;

  final emailController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ================= REGISTER =================
  Future<void> registerPatient() async {
    if (emailController.text.isEmpty ||
        usernameController.text.isEmpty ||
        passwordController.text.isEmpty) {
      showMsg("All fields are required");
      return;
    }

    setState(() => loading = true);

    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Send verification email (ONLY HERE)
      await cred.user!.sendEmailVerification();

      // Save patient data
      await _firestore.collection('patients').doc(cred.user!.uid).set({
        'email': emailController.text.trim(),
        'username': usernameController.text.trim(),
        'role': 'patient',
        'createdAt': FieldValue.serverTimestamp(),
      });

      showMsg("Verification email sent. Please verify and login.");

      setState(() => isLogin = true);
    } on FirebaseAuthException catch (e) {
      showMsg(e.message ?? "Registration failed");
    } finally {
      setState(() => loading = false);
    }
  }

  // ================= LOGIN =================
  Future<void> loginPatient() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      showMsg("Email/Username and password required");
      return;
    }

    setState(() => loading = true);

    try {
      String loginInput = emailController.text.trim();

      // If username → get email
      if (!loginInput.contains('@')) {
        final snap = await _firestore
            .collection('patients')
            .where('username', isEqualTo: loginInput)
            .limit(1)
            .get();

        if (snap.docs.isEmpty) {
          throw "Username not found";
        }

        loginInput = snap.docs.first['email'];
      }

      await _auth.signInWithEmailAndPassword(
        email: loginInput,
        password: passwordController.text.trim(),
      );

      // 🚫 NO emailVerified check here (IMPORTANT)

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomePage(role: 'patient'),
        ),
      );
    } catch (e) {
      showMsg(e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  void showMsg(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(isLogin ? "Patient Login" : "Patient Register"),
        backgroundColor: const Color(0xFF1A4D2E),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!isLogin)
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: "Username",
                  prefixIcon: Icon(Icons.person),
                ),
              ),
            if (!isLogin) const SizedBox(height: 16),

            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: isLogin ? "Email or Username" : "Email",
                prefixIcon: const Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: loading
                    ? null
                    : isLogin
                        ? loginPatient
                        : registerPatient,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A4D2E),
                ),
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(isLogin ? "Login" : "Register"),
              ),
            ),

            TextButton(
              onPressed: () {
                setState(() => isLogin = !isLogin);
              },
              child: Text(
                isLogin
                    ? "Don't have an account? Register"
                    : "Already have an account? Login",
              ),
            ),
          ],
        ),
      ),
    );
  }
}
