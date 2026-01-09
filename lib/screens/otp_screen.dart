import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  const OtpScreen({Key? key, required this.email}) : super(key: key);

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  bool isLoading = false;
  bool isVerified = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> checkEmailVerification() async {
    setState(() => isLoading = true);

    try {
      // Reload user to get updated verification status
      await _auth.currentUser!.reload();
      User? user = _auth.currentUser;

      if (user != null && user.emailVerified) {
        setState(() => isVerified = true);
        showMessage("Email verified successfully!");

        // Navigate to the next screen (home screen or role select)
        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        showMessage("Email not verified yet. Please check your inbox.");
      }
    } catch (e) {
      showMessage("Error verifying email");
      print(e);
    }

    setState(() => isLoading = false);
  }

  Future<void> resendVerificationEmail() async {
    setState(() => isLoading = true);

    try {
      await _auth.currentUser!.sendEmailVerification();
      showMessage("Verification email resent. Check your inbox.");
    } catch (e) {
      showMessage("Failed to resend email");
      print(e);
    }

    setState(() => isLoading = false);
  }

  void showMessage(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("OTP / Email Verification"),
        backgroundColor: const Color(0xFF1A4D2E),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Text(
              "A verification email has been sent to:\n${widget.email}",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : checkEmailVerification,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "I have verified my email",
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: isLoading ? null : resendVerificationEmail,
              child: const Text(
                "Resend verification email",
                style: TextStyle(decoration: TextDecoration.underline),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
