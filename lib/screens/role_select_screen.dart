
import 'package:flutter/material.dart';
import 'patien/register_patient.dart';
import 'seller/seller1.dart';
import 'doctor/docter1.dart';
import 'admin/register_admin.dart';
import 'home/home.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 40),
                _buildHeroSection(),
                const SizedBox(height: 48),
                _buildRoleCardsGrid(context),
                const SizedBox(height: 32),
                _buildFooterText(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- HERO ----------------
  Widget _buildHeroSection() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0D7E5C), Color(0xFF1B9A6C)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.eco, color: Colors.white, size: 48),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'AyurvedaCare',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            'Select your role to access personalized features and services tailored to your needs',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF64748B),
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------- ROLES ----------------
  Widget _buildRoleCardsGrid(BuildContext context) {
    final roles = [
      RoleData(
        title: 'Patient',
        subtitle: 'Book appointments, track health records',
        icon: Icons.person_outline,
        iconBgColor: const Color(0xFFD1FAE5),
        iconColor: const Color(0xFF059669),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD1FAE5), Color(0xFFECFDF5)],
        ),
        page: const RegisterPatient(),
      ),
      RoleData(
        title: 'Doctor',
        subtitle: 'Manage patients, provide consultations',
        icon: Icons.medical_services_outlined,
        iconBgColor: const Color(0xFFE0F2FE),
        iconColor: const Color(0xFF0284C7),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE0F2FE), Color(0xFFF0F9FF)],
        ),
        page: const DoctorRegisterStep1(),
      ),
      RoleData(
        title: 'Seller',
        subtitle: 'Manage products, track orders & sales',
        icon: Icons.storefront_outlined,
        iconBgColor: const Color(0xFFFEF3C7),
        iconColor: const Color(0xFFD97706),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFEF3C7), Color(0xFFFFFBEB)],
        ),
        page: const SellerRegisterStep1(),
      ),
      RoleData(
        title: 'Admin',
        subtitle: 'Manage system, users & analytics',
        icon: Icons.admin_panel_settings_outlined,
        iconBgColor: const Color(0xFFE0E7FF),
        iconColor: const Color(0xFF4F46E5),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE0E7FF), Color(0xFFEEF2FF)],
        ),
        page: const RegisterAdmin(),
      ),
    ];

    return Column(
      children: roles.map((role) {
        return Column(
          children: [
            _buildRoleCard(context, role),
            if (role != roles.last) const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  // ---------------- CARD ----------------
  Widget _buildRoleCard(BuildContext context, RoleData role) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => role.page,
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 300),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: role.gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: role.iconBgColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Icon(
                        role.icon,
                        color: role.iconColor,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          role.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          role.subtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- FOOTER ----------------
  Widget _buildFooterText() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(
        'Each role has specific features and access levels designed to enhance your AyurvedaCare experience',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          color: const Color(0xFF64748B).withOpacity(0.7),
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

// ---------------- MODEL ----------------
class RoleData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final Gradient gradient;
  final Widget page;

  RoleData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.gradient,
    required this.page,
  });
}
