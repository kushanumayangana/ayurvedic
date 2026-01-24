import 'package:flutter/material.dart';

class RegisterSellerScreen extends StatelessWidget {
  const RegisterSellerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Seller Registration")),
      body: const Center(child: Text("Register as Seller")),
    );
  }
}
