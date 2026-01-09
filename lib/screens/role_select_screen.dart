import 'package:flutter/material.dart';
import 'register_patient.dart';
import 'register_doctor.dart';
import 'register_seller.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE2E8F0), // App Background
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [

                // Logo + Title
                const SizedBox(height: 40),
                const Icon(Icons.spa, size: 80, color: Color(0xFF1A4D2E)),

                const SizedBox(height: 10),
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: "AyurVeda",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      TextSpan(
                        text: "Care",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFB347),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 5),
                const Text(
                  "Tradition meets Technology",
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),

                const SizedBox(height: 40),
                const Text(
                  "SELECT YOUR ROLE TO LOGIN",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937)),
                ),

                const SizedBox(height: 30),

                // Patient Card
                roleCard(
                  icon: Icons.person,
                  title: "Patient",
                  subtitle: "Find treatments & doctors",
                  iconColor: const Color(0xFF1A4D2E),
                  backgroundColor: const Color(0xFFF0FDF4),
                  titleColor: const Color(0xFF1F2937),
                  subtitleColor: const Color(0xFF6B7280),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RegisterPatientScreen(),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // Doctor Card
                roleCard(
                  icon: Icons.medical_services,
                  title: "Doctor",
                  subtitle: "Manage appointments",
                  iconColor: const Color(0xFF3B82F6),
                  backgroundColor: const Color(0xFFE8F0FE),
                  titleColor: const Color(0xFF1F2937),
                  subtitleColor: const Color(0xFF6B7280),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RegisterDoctor(), // ❌ no const here
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // Seller Card
                roleCard(
                  icon: Icons.store,
                  title: "Seller",
                  subtitle: "Manage shop & orders",
                  iconColor: const Color(0xFFFF9F29),
                  backgroundColor: const Color(0xFFFFF7ED),
                  titleColor: const Color(0xFF1F2937),
                  subtitleColor: const Color(0xFF6B7280),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RegisterSeller(), // ❌ no const here
                    ),
                  ),
                ),

                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A4D2E),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 60, vertical: 15),
                  ),
                  onPressed: () {},
                  child: const Text("Login securely", style: TextStyle(fontSize: 18)),
                ),

                const SizedBox(height: 15),
                const Text(
                  "Don't have an account? Register",
                  style: TextStyle(color: Color(0xFFFF9F29)),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, size: 30, color: iconColor),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: titleColor)),
              Text(subtitle, style: TextStyle(color: subtitleColor)),
            ],
          )
        ],
      ),
    ),
  );
}
