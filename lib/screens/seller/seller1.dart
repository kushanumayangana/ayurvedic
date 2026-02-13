import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'seller2.dart';
import 'sellerlogin.dart';

class SellerRegisterStep1 extends StatefulWidget {
  const SellerRegisterStep1({super.key});

  @override
  State<SellerRegisterStep1> createState() => _SellerRegisterStep1State();
}

class _SellerRegisterStep1State extends State<SellerRegisterStep1> {
  final Color primaryGold = const Color(0xFFC59D3F);
  final Color backgroundColor = const Color(0xFFF8F8F8);
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController ownerNameController = TextEditingController();
  final TextEditingController nicController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController businessNameController = TextEditingController();
  final TextEditingController businessRegController = TextEditingController();
  final TextEditingController shopAddressController = TextEditingController();
  final TextEditingController sellerTypeController = TextEditingController();

  @override
  void dispose() {
    ownerNameController.dispose();
    nicController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    businessNameController.dispose();
    businessRegController.dispose();
    shopAddressController.dispose();
    sellerTypeController.dispose();
    super.dispose();
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _registerSellerAndVerify() async {
    if (passwordController.text != confirmPasswordController.text) {
      _showMessage("Passwords do not match");
      return;
    }
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      User user = cred.user!;
      
      // Create seller document with uid as both document ID and field
      await FirebaseFirestore.instance.collection('sellers').doc(user.uid).set({
        'uid': user.uid,
        'ownerName': ownerNameController.text.trim(),
        'nicNumber': nicController.text.trim(),
        'email': user.email,
        'businessName': businessNameController.text.trim(),
        'businessRegNumber': businessRegController.text.trim(),
        'shopAddress': shopAddressController.text.trim(),
        'sellerType': sellerTypeController.text.trim(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: false));

      await user.sendEmailVerification();
      if (!mounted) return;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text("Verify Email"),
          content: const Text("Verification email sent. Please check your inbox."),
          actions: [
            TextButton(
              onPressed: () async {
                await user.reload();
                if (FirebaseAuth.instance.currentUser!.emailVerified) {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => SellerRegisterStep2(userId: user.uid)));
                } else {
                  _showMessage("Email not verified yet");
                }
              },
              child: const Text("I have verified"),
            ),
          ],
        ),
      );
    } catch (e) { _showMessage(e.toString()); }
  }

  Widget _buildTextField(String hint, IconData icon, {bool isPassword = false, TextEditingController? controller}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade400),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 60, left: 25, bottom: 40),
              decoration: BoxDecoration(
                color: primaryGold,
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Seller Registration", style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                  Text("Business Information", style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [Text("Step 1 of 2", style: TextStyle(fontSize: 12)), Text("50%", style: TextStyle(fontSize: 12))]),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: 0.5, backgroundColor: Colors.grey.shade200, valueColor: AlwaysStoppedAnimation<Color>(primaryGold)),
                  const SizedBox(height: 25),
                  
                  // Owner Card
                  _cardWrapper("Owner Details", [
                    _buildTextField("Full Name", Icons.person_outline, controller: ownerNameController),
                    _buildTextField("NIC Number", Icons.badge_outlined, controller: nicController),
                    _buildTextField("Email", Icons.email_outlined, controller: emailController),
                    _buildTextField("Password", Icons.lock_outline, isPassword: true, controller: passwordController),
                    _buildTextField("Confirm Password", Icons.lock_outline, isPassword: true, controller: confirmPasswordController),
                  ]),
                  
                  const SizedBox(height: 20),

                  // Business Card
                  _cardWrapper("Business Details", [
                    _buildTextField("Business Name", Icons.storefront, controller: businessNameController),
                    _buildTextField("Reg Number", Icons.assignment, controller: businessRegController),
                    _buildTextField("Address", Icons.location_on, controller: shopAddressController),
                    _buildTextField("Type", Icons.category, controller: sellerTypeController),
                  ]),

                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity, height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: primaryGold, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                      onPressed: _registerSellerAndVerify,
                      child: const Text("Next: Upload Documents", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerLoginScreen())),
                    child: RichText(text: TextSpan(text: "Already have an account? ", style: const TextStyle(color: Colors.grey), children: [TextSpan(text: "Login", style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold, decoration: TextDecoration.underline))])),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardWrapper(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...children,
      ]),
    );
  }
}