import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../home/home.dart';

class RegisterAdmin extends StatefulWidget {
  const RegisterAdmin({Key? key}) : super(key: key);

  @override
  State<RegisterAdmin> createState() => _RegisterAdminState();
}

class _RegisterAdminState extends State<RegisterAdmin> {
  final _formKey = GlobalKey<FormState>();
  final _loginFormKey = GlobalKey<FormState>();

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final TextEditingController loginEmailController = TextEditingController();
  final TextEditingController loginPasswordController = TextEditingController();

  bool loading = false;
  bool showLoginForm = true; // toggle between login and register

  final Color navyBlue = const Color(0xFF1D2671);
  final Color lightBg = const Color(0xFFE8EEF0);

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    loginEmailController.dispose();
    loginPasswordController.dispose();
    super.dispose();
  }

  // ================= REGISTER ADMIN =================
  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => loading = true);

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection("admins")
          .doc(userCredential.user!.uid)
          .set({
        "uid": userCredential.user!.uid,
        "fullName": fullNameController.text.trim(),
        "email": emailController.text.trim(),
        "role": "admin",
        "status": "active",
        "createdAt": FieldValue.serverTimestamp(),
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage(role: "admin")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => loading = false);
    }
  }

  // ================= ADMIN LOGIN =================
  Future<void> login() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() => loading = true);

    try {
      final email = loginEmailController.text.trim();
      final password = loginPasswordController.text.trim();

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // OPTIONAL: check email allowlist
      // final allowedAdmins = ["admin@gmail.com"];
      // if (!allowedAdmins.contains(email)) throw "Not an admin";

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage(role: "admin")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => loading = false);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // HEADER
            Container(
              width: double.infinity,
              height: 240,
              decoration: BoxDecoration(
                color: lightBg,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      Icon(Icons.security, color: navyBlue, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        "AyurvedaCare",
                        style: TextStyle(
                          color: navyBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    showLoginForm ? "Admin Login" : "Admin Registration",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: navyBlue,
                    ),
                  ),
                ],
              ),
            ),

            // FORM
            Padding(
              padding: const EdgeInsets.all(24),
              child: showLoginForm ? loginForm() : registrationForm(),
            ),

            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => setState(() => showLoginForm = !showLoginForm),
              child: RichText(
                text: TextSpan(
                  text: showLoginForm
                      ? "New admin? "
                      : "Already have an account? ",
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                  children: [
                    TextSpan(
                      text: showLoginForm ? "Register" : "Login",
                      style: TextStyle(
                          color: navyBlue, fontWeight: FontWeight.bold),
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

  // ================= FORMS =================
  Widget registrationForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildField(fullNameController, Icons.person, "Full Name"),
          const SizedBox(height: 20),
          _buildField(emailController, Icons.email, "Email"),
          const SizedBox(height: 20),
          _buildField(passwordController, Icons.lock, "Password", isPass: true),
          const SizedBox(height: 40),
          _submitButton("Create Admin", submit),
        ],
      ),
    );
  }

  Widget loginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        children: [
          _buildField(loginEmailController, Icons.email, "Email"),
          const SizedBox(height: 20),
          _buildField(loginPasswordController, Icons.lock, "Password", isPass: true),
          const SizedBox(height: 40),
          _submitButton("Login", login),
        ],
      ),
    );
  }

  // ================= HELPERS =================
  Widget _buildField(TextEditingController controller, IconData icon, String hint,
      {bool isPass = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPass,
      validator: (v) => v == null || v.isEmpty ? "Required" : null,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  Widget _submitButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: navyBlue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        onPressed: loading ? null : onPressed,
        child: loading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(text, style: const TextStyle(color: Colors.white, fontSize: 16)),
      ),
    );
  }
}
