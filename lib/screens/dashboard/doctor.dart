import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DoctorDashboard extends StatelessWidget {
  const DoctorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Doctor Dashboard"),
        backgroundColor: Colors.green[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              elevation: 5,
              child: ListTile(
                leading: const Icon(Icons.person, color: Colors.green),
                title: const Text("My Profile"),
                subtitle: const Text("View & edit your profile details"),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Profile page coming soon")));
                },
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 5,
              child: ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.green),
                title: const Text("Appointments"),
                subtitle: const Text("View your upcoming appointments"),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Appointments page coming soon")));
                },
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 5,
              child: ListTile(
                leading: const Icon(Icons.settings, color: Colors.green),
                title: const Text("Settings"),
                subtitle: const Text("Manage app preferences"),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Settings page coming soon")));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
