import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../doctor/appointment/book_appointment.dart'; 
// import '../doctor/profile/doctor_profile_detail.dart'; // Ensure this exists
import '../dashboard/admin.dart';
import '../dashboard/doctor.dart';
import '../dashboard/patient.dart';
import '../dashboard/seller.dart';

class HomePage extends StatefulWidget {
  final String role;
  const HomePage({super.key, required this.role});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Color primaryGreen = const Color(0xFF24615E); 
  final Color lightBg = const Color(0xFFF9FBFB);
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 25),
                  
                  // --- DOCTOR CHANNELING ---
                  _buildSectionHeader("Doctor Channeling"),
                  const SizedBox(height: 15),
                  _buildSearchField("Search Medicines, doctors..."),
                  const SizedBox(height: 15),
                  _buildDoctorList(),

                  const SizedBox(height: 30),

                  // --- MARKET PLACE ---
                  _buildSectionHeader("Market Place", subTitle: "Popular Medicines"),
                  const SizedBox(height: 15),
                  _buildProductList(),

                  const SizedBox(height: 30),

                  // --- LEARN HUB ---
                  _buildSectionHeader("Learn Hub"),
                  const SizedBox(height: 15),
                  _buildLearnHubSearch(),
                  const SizedBox(height: 20),
                  _buildArticleList(),
                  const SizedBox(height: 100), 
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // --- HEADER COMPONENT ---
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
          const Text("AyurvedaCare", style: TextStyle(color: Color(0xFF4C7B5C), fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 10),
          Text("Hello, John", 
              style: TextStyle(color: primaryGreen, fontSize: 28, fontWeight: FontWeight.bold)),
          const Text("How are you feeling today?", 
              style: TextStyle(color: Color(0xFF6A9175), fontSize: 16)),
        ],
      ),
    );
  }

  // --- DOCTOR LIST COMPONENT ---
  Widget _buildDoctorList() {
    return SizedBox(
      height: 160,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("doctors").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          return ListView(
            scrollDirection: Axis.horizontal,
            children: snapshot.data!.docs.map((doc) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              return _buildDoctorCard(doc.id, data['fullName'] ?? "Doctor", data['specialization'] ?? "Specialist", data['profileImage'] ?? "");
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildDoctorCard(String id, String name, String specialty, String image) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 15, bottom: 5),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 35, backgroundImage: image.isNotEmpty ? NetworkImage(image) : null, backgroundColor: Colors.grey.shade200),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1B4332))),
                Text(specialty, style: const TextStyle(color: Color(0xFF2D6A4F), fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildSmallTag("Online"),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookAppointmentPage(doctorId: id, doctorName: name))),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: primaryGreen, borderRadius: BorderRadius.circular(10)),
                        child: const Text("Book Appoi...", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- MARKET PLACE COMPONENT ---
  Widget _buildProductList() {
    return SizedBox(
      height: 200,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildProductCard("Ashwagandha", "Immunity Booster", "\$12.99"),
          _buildProductCard("Neem Balm", "Skin Care", "\$10.50"),
          _buildProductCard("Brahmi Tea", "Mind Health", "\$15.00"),
        ],
      ),
    );
  }

  Widget _buildProductCard(String name, String type, String price) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 15, bottom: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: const Color(0xFFF1F7F2), borderRadius: BorderRadius.circular(15)),
              width: double.infinity, 
              child: const Icon(Icons.eco, color: Color(0xFF2D6A4F), size: 40)
            ),
          ),
          const SizedBox(height: 10),
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B4332))),
          Text(type, style: const TextStyle(color: Colors.grey, fontSize: 10)),
          const SizedBox(height: 5),
          Text(price, style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  // --- LEARN HUB SECTION (UPDATED) ---
  Widget _buildLearnHubSearch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black12),
      ),
      child: const TextField(
        decoration: InputDecoration(
          hintText: "Search articles...",
          hintStyle: TextStyle(color: Colors.black26, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.black26),
          suffixIcon: Icon(Icons.arrow_circle_up, color: Colors.black12),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildArticleList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("articles").snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        return Column(
          children: snapshot.data!.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            String docId = data['doctorId'] ?? "";
            String docName = data['doctorName'] ?? "Specialist";

            return Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.black.withOpacity(0.05)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['title'] ?? "Title",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF1B4332)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data['content'] ?? "",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(radius: 10, backgroundColor: primaryGreen.withOpacity(0.1), child: Icon(Icons.person, size: 12, color: primaryGreen)),
                          const SizedBox(width: 8),
                          Text("By Dr. $docName", style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          // TODO: Navigate to doctor detail page if you have one
                          // Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorProfileDetail(doctorId: docId)));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: primaryGreen, borderRadius: BorderRadius.circular(12)),
                          child: const Row(
                            children: [
                              Text("View Profile", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_ios, size: 9, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // --- HELPER COMPONENTS ---
  Widget _buildSectionHeader(String title, {String? subTitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryGreen)),
            const Text("View All", style: TextStyle(color: Color(0xFF7BA688), fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
        if (subTitle != null) ...[
          const SizedBox(height: 4),
          Text(subTitle, style: const TextStyle(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.w600)),
        ]
      ],
    );
  }

  Widget _buildSearchField(String hint) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: TextField(
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search, color: Colors.black26),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black26, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildSmallTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: const Color(0xFFF1F7F2), borderRadius: BorderRadius.circular(10)),
      child: Text(label, style: const TextStyle(color: Color(0xFF2D6A4F), fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      selectedItemColor: primaryGreen,
      unselectedItemColor: Colors.black38,
      showUnselectedLabels: true,
      backgroundColor: Colors.white,
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        setState(() => _selectedIndex = index);
        if (index == 3) _onDashboardTapped();
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: "Shop"),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today_rounded), label: "Appointment"),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: "Profile"),
      ],
    );
  }

  void _onDashboardTapped() {
    Widget dest;
    switch (widget.role.toLowerCase()) {
      case 'doctor': dest = const DoctorDashboard(); break;
      case 'seller': dest = const SellerDashboard(); break;
      default: dest = const PatientDashboard();
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => dest));
  }
}