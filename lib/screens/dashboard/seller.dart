import 'package:flutter/material.dart';

class SellerDashboard extends StatelessWidget {
  const SellerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.storefront, size: 80, color: Colors.amber),
          SizedBox(height: 20),
          Text(
            "Seller Dashboard",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            "Here you can manage your products, orders, and profile",
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
