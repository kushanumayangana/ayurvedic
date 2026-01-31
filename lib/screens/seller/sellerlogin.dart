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
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      final querySnapshot = await FirebaseFirestore.instance.collection('sellers').where('email', isEqualTo: emailController.text.trim()).get();
      if (querySnapshot.docs.isEmpty) throw "Seller not found";
      
      final data = querySnapshot.docs.first.data();
      if (data['status'] != 'approved') throw "Account pending approval";

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage(role: data['role'] ?? 'seller')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 80, left: 30, bottom: 40),
            decoration: BoxDecoration(color: primaryGold, borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40))),
            child: const Text("Seller Login", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              children: [
                TextField(controller: emailController, decoration: const InputDecoration(labelText: "Email")),
                const SizedBox(height: 20),
                TextField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: "Password")),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: primaryGold),
                    onPressed: loading ? null : loginUser,
                    child: loading ? const CircularProgressIndicator() : const Text("Login", style: TextStyle(color: Colors.white)),
                  ),
                ),
                TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerRegisterStep1())), child: const Text("New Business? Register"))
              ],
            ),
          )
        ],
      ),
    );
  }
}