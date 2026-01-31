import 'package:flutter/material.dart';


import '../dashboard/admin.dart';
import '../dashboard/doctor.dart';
import '../dashboard/patient.dart';
import '../dashboard/seller.dart';


class HomePage extends StatelessWidget {
  final String role; // Role passed from login/registration

  const HomePage({Key? key, required this.role}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color primaryGreen = const Color(0xFF24615E);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
        backgroundColor: primaryGreen,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to the Home Page!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                // Navigate to the dashboard depending on the role
                if (role == 'admin') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AdminDashboard()),
                  );
                } else if (role == 'seller') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SellerDashboard()),
                  );
                } else if (role == 'doctor') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const DoctorDashboard()),
                  );
                } else if (role == 'patient') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PatientDashboard()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Role not recognized')),
                  );
                }
              },
              child: const Text(
                'Go to Dashboard',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
