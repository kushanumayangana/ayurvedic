// lib/screens/seller/seller_login.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'seller1.dart';
import '../home/home.dart';

class SellerLoginScreen extends StatefulWidget {
  const SellerLoginScreen({super.key});

  @override
  State<SellerLoginScreen> createState() => _SellerLoginScreenState();
}

class _SellerLoginScreenState extends State<SellerLoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Color primaryGold = const Color(0xFFC59D3F);
  bool loading = false;

  // --- LOGIC FUNCTIONS ---
  Future<void> loginUser() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) return;

    setState(() => loading = true);

    try {
      // Sign in with Firebase Auth
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final uid = cred.user!.uid;
      debugPrint("AUTH UID: $uid");

      // First, try to fetch by document ID (since registration stores doc(user.uid))
      DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
          .collection('sellers')
          .doc(uid)
          .get();

      if (!docSnapshot.exists) {
        // Fallback: query by uid field if document ID doesn't match
        final query = await FirebaseFirestore.instance
            .collection('sellers')
            .where('uid', isEqualTo: uid)
            .limit(1)
            .get();

        if (query.docs.isEmpty) {
          throw Exception('Seller profile not found. Please complete registration first.');
        }
        docSnapshot = query.docs.first;
      }

      final data = docSnapshot.data() as Map<String, dynamic>;

      // Check approval status (allow 'pending' or 'approved')
      final status = data['status'] ?? 'pending';
      if (status == 'rejected') {
        throw Exception('Account has been rejected');
      }

      // Navigate to HomePage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomePage(role: data['sellerType'] ?? 'seller'),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed';
      if (e.code == 'user-not-found') {
        message = 'No account found with this email';
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect password';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // --- HEADER ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 80, left: 30, bottom: 40),
            decoration: BoxDecoration(
              color: primaryGold,
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40)),
            ),
            child: const Text(
              "Seller Login",
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // --- LOGIN FORM ---
          Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              children: [
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: "Email"),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Password"),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: primaryGold),
                    onPressed: loading ? null : loginUser,
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Login",
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SellerRegisterStep1()),
                    );
                  },
                  child: const Text("New Business? Register"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
