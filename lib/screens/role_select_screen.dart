import 'package:flutter/material.dart';
import 'register_patient.dart';
import 'register_doctor.dart';
import 'register_seller.dart';

class RoleSelectScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE2E8F0), // App Background
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [

                // Logo + Title
                SizedBox(height: 40),
                Icon(Icons.spa, size: 80, color: Color(0xFF1A4D2E)), // Deep Forest Green

                SizedBox(height: 10),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: "AyurVeda",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937), // Main Text
                        ),
                      ),
                      TextSpan(
                        text: "Care",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFB347), // Warm Gold
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 5),
                Text(
                  "Tradition meets Technology",
                  style: TextStyle(color: Color(0xFF6B7280)), // Sub Text
                ),

                SizedBox(height: 40),
                Text(
                  "SELECT YOUR ROLE TO LOGIN",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                ),

                SizedBox(height: 30),

                // Patient Card
                roleCard(
                  icon: Icons.person,
                  title: "Patient",
                  subtitle: "Find treatments & doctors",
                  iconColor: Color(0xFF1A4D2E), // Deep Forest Green
                  backgroundColor: Color(0xFFF0FDF4), // Soft Green Bg
                  titleColor: Color(0xFF1F2937),
                  subtitleColor: Color(0xFF6B7280),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => RegisterPatient()),
                  ),
                ),

                SizedBox(height: 15),

                // Doctor Card
                roleCard(
                  icon: Icons.medical_services,
                  title: "Doctor",
                  subtitle: "Manage appointments",
                  iconColor: Color(0xFF3B82F6), // Medical Blue
                  backgroundColor: Color(0xFFE8F0FE), // Light Blue
                  titleColor: Color(0xFF1F2937),
                  subtitleColor: Color(0xFF6B7280),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => RegisterDoctor()),
                  ),
                ),

                SizedBox(height: 15),

                // Seller Card
                roleCard(
                  icon: Icons.store,
                  title: "Seller",
                  subtitle: "Manage shop & orders",
                  iconColor: Color(0xFFFF9F29), // Vibrant Orange
                  backgroundColor: Color(0xFFFFF7ED), // Orange Bg
                  titleColor: Color(0xFF1F2937),
                  subtitleColor: Color(0xFF6B7280),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => RegisterSeller()),
                  ),
                ),

                SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1A4D2E), // Deep Forest Green
                    padding: EdgeInsets.symmetric(horizontal: 60, vertical: 15),
                  ),
                  onPressed: () {},
                  child: Text("Login securely", style: TextStyle(fontSize: 18)),
                ),

                SizedBox(height: 15),
                Text(
                  "Don't have an account? Register",
                  style: TextStyle(color: Color(0xFFFF9F29)), // Vibrant Orange
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Reusable role card widget
Widget roleCard({
  required IconData icon,
  required String title,
  required String subtitle,
  required Function onTap,
  required Color iconColor,
  required Color backgroundColor,
  required Color titleColor,
  required Color subtitleColor,
}) {
  return InkWell(
    onTap: () => onTap(),
    child: Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, size: 30, color: iconColor),
          SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: titleColor)),
              Text(subtitle, style: TextStyle(color: subtitleColor)),
            ],
          )
        ],
      ),
    ),
  );
}
