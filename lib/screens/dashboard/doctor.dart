import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../doctor/article/add_article.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  // Color Palette
  final Color primaryGreen = const Color(0xFF24615E);
  final Color secondaryGreen = const Color(0xFF1B4332);
  final Color bgLight = const Color(0xFFF9FBFB);
  
  final String doctorId = FirebaseAuth.instance.currentUser?.uid ?? "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------- HEADER SECTION ----------
            _buildHeader(),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---------- ACTION BUTTONS ----------
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          label: "Add Medicine",
                          icon: Icons.medical_services_outlined,
                          color: primaryGreen,
                          textColor: Colors.white,
                          onTap: () {
                            // Logic for adding products/medicine
                          },
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildActionButton(
                          label: "Write Article",
                          icon: Icons.history_edu_rounded,
                          color: Colors.white,
                          textColor: primaryGreen,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AddArticlePage()),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 35),

                  // ---------- APPOINTMENT REQUESTS ----------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Appointment Requests", 
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: secondaryGreen)),
                      Text("View All", 
                        style: TextStyle(color: primaryGreen, fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 15),

                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('appointments')
                        .where('doctorId', isEqualTo: doctorId)
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
                          return _buildScheduleTile(
                            id: doc.id,
                            name: data['patientName'] ?? "Unknown Patient",
                            status: data['status'] ?? 'pending',
                          );
                        }).toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 30),
                  Text("Recent Orders", 
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: secondaryGreen)),
                  const SizedBox(height: 15),
                  _buildOrderPlaceholder(),
                  const SizedBox(height: 100), // Bottom padding for scrolling
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, left: 25, right: 25, bottom: 40),
      decoration: const BoxDecoration(
        color: Color(0xFFE8F1E9),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("AyurvedaCare", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryGreen)),
          const SizedBox(height: 10),
          Text("Doctor Dashboard", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: secondaryGreen)),
          const Text("Manage your patients and schedule", style: TextStyle(color: Color(0xFF6A9175), fontSize: 14)),
          const SizedBox(height: 25),
          
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('appointments')
                .where('doctorId', isEqualTo: doctorId)
                .snapshots(),
            builder: (context, snapshot) {
              int total = snapshot.hasData ? snapshot.data!.docs.length : 0;
              int approved = snapshot.hasData ? snapshot.data!.docs.where((d) => d['status'] == 'approved').length : 0;
              int pending = snapshot.hasData ? snapshot.data!.docs.where((d) => d['status'] == 'pending').length : 0;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatCard(total.toString(), "Bookings", Icons.calendar_month_rounded),
                  _buildStatCard(approved.toString(), "Success", Icons.check_circle_outline),
                  _buildStatCard(pending.toString(), "Pending", Icons.hourglass_bottom_rounded),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.27,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]
      ),
      child: Column(
        children: [
          Icon(icon, color: primaryGreen, size: 20),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: secondaryGreen)),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildActionButton({required String label, required IconData icon, required Color color, required Color textColor, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: color, 
          borderRadius: BorderRadius.circular(25),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8))],
          border: color == Colors.white ? Border.all(color: Colors.black.withOpacity(0.05)) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 28),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleTile({required String id, required String name, required String status}) {
    bool isPending = status == 'pending';
    bool isApproved = status == 'approved';

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: isApproved ? Colors.green.withOpacity(0.2) : 
                 status == 'rejected' ? Colors.red.withOpacity(0.2) : Colors.transparent
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]
      ),
      child: Row(
        children: [
          // Left Time Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isApproved ? const Color(0xFFE8F1E9) : const Color(0xFFF1F7F2), 
              borderRadius: BorderRadius.circular(15)
            ),
            child: Column(
              children: [
                Text("09:30", style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 13)),
                Text("AM", style: TextStyle(color: primaryGreen, fontSize: 9, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 15),
          
          // Patient Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: secondaryGreen)),
                Text(
                  status == 'pending' ? "Needs Review" : 
                  status == 'approved' ? "Confirmed Success" : "Rejected/Failed",
                  style: TextStyle(
                    color: isApproved ? Colors.green : 
                           status == 'rejected' ? Colors.red : Colors.orange, 
                    fontSize: 11, fontWeight: FontWeight.bold
                  ),
                ),
              ],
            ),
          ),

          // Action Buttons
          if (isPending)
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    FirebaseFirestore.instance.collection('appointments').doc(id).update({'status': 'rejected'});
                  },
                  icon: const Icon(Icons.close_rounded, color: Colors.redAccent),
                ),
                const SizedBox(width: 4),
                ElevatedButton(
                  onPressed: () {
                    FirebaseFirestore.instance.collection('appointments').doc(id).update({'status': 'approved'});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text("Accept", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            )
          else
            Icon(
              isApproved ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: isApproved ? Colors.green : Colors.red,
              size: 28,
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.black.withOpacity(0.02)),
      ),
      child: const Column(
        children: [
          Icon(Icons.calendar_today_outlined, color: Colors.grey, size: 40),
          SizedBox(height: 10),
          Text("No appointments found", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildOrderPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            height: 50, width: 50,
            decoration: BoxDecoration(color: const Color(0xFFF1F7F2), borderRadius: BorderRadius.circular(15)),
            child: Icon(Icons.shopping_bag_outlined, color: primaryGreen),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Herbal Package", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text("Order #4829 - Processing", style: TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          const Text("\$24.00", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
        ],
      ),
    );
  }
}