import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  final Color primaryGreen = const Color(0xFF24615E);
  final Color secondaryGreen = const Color(0xFF1B4332);
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFB),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------- HEADER ----------
            _buildHeader(),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("My Appointments", 
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: secondaryGreen)),
                  const SizedBox(height: 15),

                  // ---------- APPOINTMENT LIST ----------
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('appointments')
                        .where('patientId', isEqualTo: userId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data?.docs ?? [];

                      if (docs.isEmpty) {
                        return _buildEmptyState();
                      }

                      return Column(
                        children: docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return _buildAppointmentTile(data);
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, left: 25, right: 25, bottom: 30),
      decoration: BoxDecoration(
        color: primaryGreen,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Welcome back,", style: TextStyle(color: Colors.white70, fontSize: 14)),
          const Text("Your Health Matters", 
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text("Check your appointment status below to see if the doctor has accepted.", 
                    style: TextStyle(color: Colors.white, fontSize: 12)),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAppointmentTile(Map<String, dynamic> data) {
    String status = data['status'] ?? 'pending';
    
    // UI logic based on status
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (status == 'approved') {
      statusColor = Colors.green;
      statusText = "Your appointment is success!";
      statusIcon = Icons.check_circle_rounded;
    } else if (status == 'rejected') {
      statusColor = Colors.red;
      statusText = "Appointment failed: Doctor unavailable";
      statusIcon = Icons.cancel_rounded;
    } else {
      statusColor = Colors.orange;
      statusText = "Waiting for doctor's response...";
      statusIcon = Icons.hourglass_empty_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
        border: Border.all(color: statusColor.withOpacity(0.1), width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: statusColor.withOpacity(0.1),
                child: Icon(Icons.person, color: statusColor),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Dr. ${data['doctorName'] ?? 'Ayurvedic Specialist'}", 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: secondaryGreen)),
                    const Text("General Consultation", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Icon(statusIcon, color: statusColor),
            ],
          ),
          const Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(statusText, 
                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13)),
              if (status == 'approved')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(10)),
                  child: const Text("JOIN CALL", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 50),
          Icon(Icons.calendar_today_outlined, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 10),
          const Text("No appointments booked yet.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}