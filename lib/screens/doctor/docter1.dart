import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'doctor2.dart';
import 'doctor_login.dart';

class DoctorRegisterStep1 extends StatefulWidget {
  const DoctorRegisterStep1({super.key});

  @override
  State<DoctorRegisterStep1> createState() => _DoctorRegisterStep1State();
}

class _DoctorRegisterStep1State extends State<DoctorRegisterStep1> {
  final fullName = TextEditingController();
  final nic = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();

  bool loading = false;
  bool waitingForVerification = false;

  final Color headerBgColor = const Color(0xFFE9EFEE);
  final Color darkGreen = const Color(0xFF1E5653);
  final Color primaryGreen = const Color(0xFF24615E);

  Future<void> register() async {
    if (password.text != confirmPassword.text) {
      show("Passwords do not match");
      return;
    }

    try {
      setState(() {
        loading = true;
        waitingForVerification = false;
      });

      UserCredential cred =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      await cred.user!.sendEmailVerification();

      show("Verification email sent. Please verify.");

      setState(() => waitingForVerification = true);

      _startAutoVerificationCheck(cred.user!);
    } catch (e) {
      show(e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  /// 🔁 AUTO CHECK EMAIL VERIFICATION
  void _startAutoVerificationCheck(User user) async {
    while (true) {
      await Future.delayed(const Duration(seconds: 3));
      await user.reload();

      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null && currentUser.emailVerified) {
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DoctorRegisterStep2(
              uid: currentUser.uid,
              fullName: fullName.text,
              nic: nic.text,
              email: email.text,
            ),
          ),
        );
        break;
      }
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
            /// HEADER (UNCHANGED)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                  left: 24, right: 24, top: 60, bottom: 40),
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
                  Text("Doctor Portal",
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: darkGreen)),
                  const SizedBox(height: 8),
                  Text("Secure access for medical professionals",
                      style: TextStyle(
                          color: darkGreen.withOpacity(0.7), fontSize: 14)),
                ],
              ),
            ),

            /// FORM (UNCHANGED DESIGN)
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
                    field("Full Name", fullName, Icons.person_outline),
                    field("NIC / Medical ID", nic, Icons.badge_outlined),
                    field("Email Address", email, Icons.email_outlined),
                    field("Password", password, Icons.lock_outline, true),
                    field("Confirm Password", confirmPassword,
                        Icons.lock_reset_outlined, true),

                    const SizedBox(height: 20),

                    if (waitingForVerification)
                      const Text(
                        "Waiting for email verification...",
                        style: TextStyle(color: Colors.grey),
                      ),

                    const SizedBox(height: 10),

                    /// NEXT BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: loading ? null : register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: loading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                "Next",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// LOGIN BUTTON
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const DoctorLoginScreen()),
                        );
                      },
                      child: const Text(
                        "Already registered? Doctor Login",
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF24615E)),
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
