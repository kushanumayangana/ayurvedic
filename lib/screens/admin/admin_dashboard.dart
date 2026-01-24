import 'package:flutter/material.dart';
import 'doctor_approval_list.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: Colors.green[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              elevation: 5,
              child: ListTile(
                leading: const Icon(Icons.person_add, color: Colors.green),
                title: const Text("Doctor Approvals"),
                subtitle: const Text("View & approve pending doctors"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const DoctorApprovalList()),
                  );
                },
              ),
            ),
            // You can add more admin stats/cards here
          ],
        ),
      ),
    );
  }
}
