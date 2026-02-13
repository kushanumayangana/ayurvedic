import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookAppointmentPage extends StatefulWidget {
  final String doctorId;
  final String doctorName;

  const BookAppointmentPage({
    super.key,
    required this.doctorId,
    required this.doctorName,
  });

  @override
  State<BookAppointmentPage> createState() => _BookAppointmentPageState();
}

class _BookAppointmentPageState extends State<BookAppointmentPage> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  bool loading = false;

  // Custom Colors to match your UI
  final Color primaryGreen = const Color(0xFF24615E);

  Future<void> _bookAppointment() async {
    // 1. Validate Doctor ID
    if (widget.doctorId.isEmpty) {
      _showSnackBar("Error: Doctor information missing.");
      return;
    }

    // 2. Check User Authentication
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar("Please login to book an appointment.");
      return;
    }

    setState(() => loading = true);

    try {
      // 3. Construct DateTime
      final appointmentDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      // 4. Save to Firestore
      await FirebaseFirestore.instance.collection('appointments').add({
        "doctorId": widget.doctorId,
        "doctorName": widget.doctorName,
        "patientId": user.uid,
        "patientName": user.displayName ?? "Patient ${user.uid.substring(0, 5)}",
        "status": "pending",
        "date": "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}",
        "time": "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}",
        "reason": "Consultation",
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      _showSnackBar("✅ Appointment booked! Waiting for doctor approval...");
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.pop(context);
      
    } catch (e) {
      _showSnackBar("Booking failed: ${e.toString()}");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: primaryGreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Book - ${widget.doctorName}"),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select your preferred slot",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // Date Picker Card
            _buildSelectionCard(
              title: "Appointment Date",
              value: "${selectedDate.toLocal()}".split(' ')[0],
              icon: Icons.calendar_month,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (date != null) setState(() => selectedDate = date);
              },
            ),

            const SizedBox(height: 15),

            // Time Picker Card
            _buildSelectionCard(
              title: "Appointment Time",
              value: selectedTime.format(context),
              icon: Icons.access_time,
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: selectedTime,
                );
                if (time != null) setState(() => selectedTime = time);
              },
            ),

            const Spacer(),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: loading ? null : _bookAppointment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Confirm Booking",
                        style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionCard({
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(icon, color: primaryGreen),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}