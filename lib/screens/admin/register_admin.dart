import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../home/home.dart'; // Home page handles dashboard selection

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
  bool showLoginForm = false;
  final Color primaryGreen = const Color(0xFF24615E);

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    loginEmailController.dispose();
    loginPasswordController.dispose();
    super.dispose();
  }

  // Registration function
  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      String uid = userCredential.user!.uid;

      await FirebaseFirestore.instance.collection("admins").doc(uid).set({
        "fullName": fullNameController.text.trim(),
        "email": emailController.text.trim(),
        "role": "admin",
        "status": "active",
        "createdAt": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Admin Registered Successfully!")),
      );

      // Navigate to HomePage with role
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomePage(role: "admin"),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message = "";
      if (e.code == "email-already-in-use") {
        message = "This email is already registered";
      } else if (e.code == "weak-password") {
        message = "Password should be at least 6 characters";
      } else {
        message = e.message ?? "An error occurred";
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      setState(() => loading = false);
    }
  }

  // Login function
  Future<void> login() async {
    if (!_loginFormKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: loginEmailController.text.trim(),
        password: loginPasswordController.text.trim(),
      );

      String uid = userCredential.user!.uid;

      // Get role from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection("admins") // If all users are in one collection, adjust
          .doc(uid)
          .get();

      String role = userDoc['role'];

      // Navigate to HomePage with role
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomePage(role: role),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message = "";
      if (e.code == "user-not-found") {
        message = "No admin found with this email";
      } else if (e.code == "wrong-password") {
        message = "Incorrect password";
      } else {
        message = e.message ?? "An error occurred";
      }
      show(message);
    } finally {
      setState(() => loading = false);
    }
  }

  void show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  showLoginForm ? "Admin Login" : "Admin Registration",
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  showLoginForm
                      ? "Enter your email and password to login"
                      : "Fill in the details to create an admin account",
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                showLoginForm ? loginForm() : registrationForm(),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        showLoginForm = !showLoginForm;
                      });
                    },
                    child: Text(
                      showLoginForm
                          ? "Don't have an account? Register"
                          : "Already have an account? Login",
                      style: TextStyle(
                          color: primaryGreen, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget registrationForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildTextField(
              controller: fullNameController,
              label: "Full Name",
              validatorMsg: "Please enter full name"),
          const SizedBox(height: 16),
          _buildTextField(
              controller: emailController,
              label: "Email",
              keyboardType: TextInputType.emailAddress,
              validatorMsg: "Please enter a valid email"),
          const SizedBox(height: 16),
          _buildTextField(
              controller: passwordController,
              label: "Password",
              obscureText: true,
              validatorMsg: "Please enter a password"),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: loading ? null : submit,
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "Register Admin",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget loginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        children: [
          _buildTextField(
              controller: loginEmailController,
              label: "Email",
              keyboardType: TextInputType.emailAddress,
              validatorMsg: "Please enter a valid email"),
          const SizedBox(height: 16),
          _buildTextField(
              controller: loginPasswordController,
              label: "Password",
              obscureText: true,
              validatorMsg: "Please enter password"),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[700],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: loading ? null : login,
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "Login",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    required String validatorMsg,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: (val) => val == null || val.isEmpty ? validatorMsg : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
