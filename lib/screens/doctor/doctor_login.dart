import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'doctor_dashboard.dart'; // <-- your doctor dashboard screen
import '../../constants/colors.dart';

class DoctorLoginScreen extends StatefulWidget {
  const DoctorLoginScreen({super.key});

  @override
  State<DoctorLoginScreen> createState() => _DoctorLoginScreenState();
}

class _DoctorLoginScreenState extends State<DoctorLoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool loading = false;

  final Color headerBgColor = const Color(0xFFE9EFEE);
  final Color darkGreen = const Color(0xFF1E5653);
  final Color primaryGreen = const Color(0xFF24615E);

  void login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      show("Please fill all fields");
      return;
    }

    setState(() => loading = true);

    try {
      // Sign in with Firebase Auth
      UserCredential cred = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
              email: emailController.text.trim(),
              password: passwordController.text.trim());

      String uid = cred.user!.uid;

      // Check doctor approval in Firestore
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection("doctors")
          .doc(uid)
          .get();

      if (!doc.exists) {
        show("Doctor record not found");
      } else {
        final data = doc.data() as Map<String, dynamic>;
        if (data['status'] != 'approved') {
          show("Your account is not approved yet");
        } else {
          // Navigate to Doctor Dashboard
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DoctorDashboard()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String msg = "";
      if (e.code == "user-not-found") {
        msg = "No doctor found with this email";
      } else if (e.code == "wrong-password") {
        msg = "Incorrect password";
      } else {
        msg = e.message ?? "Login failed";
      }
      show(msg);
    } catch (e) {
      show("Error: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  void show(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // HEADER
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.only(left: 24, right: 24, top: 60, bottom: 40),
              decoration: BoxDecoration(
                color: headerBgColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.medical_services_outlined, color: darkGreen),
                      const SizedBox(width: 8),
                      Text("AyurvedaCare",
                          style: TextStyle(
                              color: darkGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text("Doctor Login",
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: darkGreen)),
                  const SizedBox(height: 8),
                  Text("Secure login for approved doctors",
                      style: TextStyle(
                          color: darkGreen.withOpacity(0.7), fontSize: 14)),
                ],
              ),
            ),

            // LOGIN FORM
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    field("Email Address", emailController, Icons.email_outlined),
                    field("Password", passwordController, Icons.lock_outline, true),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: loading ? null : login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: loading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("Login",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget field(String label, TextEditingController c, IconData icon,
      [bool hide = false]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey,
                fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: c,
          obscureText: hide,
          decoration: InputDecoration(
            hintText: "Enter $label",
            prefixIcon: Icon(icon, size: 20),
            filled: true,
            fillColor: Colors.white,
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
