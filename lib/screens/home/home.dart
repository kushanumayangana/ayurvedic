import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../doctor/appointment/book_appointment.dart';
import '../dashboard/doctor.dart';
import '../dashboard/patient.dart';
import '../dashboard/admin.dart';
import '../doctor/doctor_profile.dart';
import '../patien/article_detail.dart';

class HomePage extends StatefulWidget {
  final String role;
  const HomePage({super.key, required this.role});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Color primaryGreen = const Color(0xFF24615E);
  final Color secondaryGreen = const Color(0xFF1B4332);
  final Color lightBg = const Color(0xFFF9FBFB);

  int _selectedIndex = 0;
  final user = FirebaseAuth.instance.currentUser;

  String doctorSearch = "";
  String articleSearch = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 25),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle("Doctor Channeling"),
                    const SizedBox(height: 15),
                    _searchBox("Search doctors...", (value) => setState(() => doctorSearch = value)),
                    const SizedBox(height: 15),
                    SizedBox(
                      height: 180,
                      child: _doctorList(),
                    ),
                    const SizedBox(height: 35),
                    _sectionTitle("Learn Hub"),
                    const SizedBox(height: 15),
                    _searchBox("Search articles...", (value) => setState(() => articleSearch = value)),
                    const SizedBox(height: 15),
                    _articleList(),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(25, 60, 25, 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE8F1E9), Color(0xFFD2E7D6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("AyurvedaCare", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text("Welcome 👋", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: secondaryGreen)),
                const SizedBox(height: 5),
                const Text("Book doctors & learn Ayurveda", style: TextStyle(color: Color(0xFF6A9175))),
              ],
            ),
          ),
          IconButton(
            onPressed: _openDashboard,
            icon: Icon(Icons.dashboard, color: primaryGreen),
            tooltip: 'Open Dashboard',
          ),
        ],
      ),
    );
  }

  Widget _doctorList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("doctors").snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final filteredDocs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['fullName'].toString().toLowerCase().contains(doctorSearch.toLowerCase());
        }).toList();

        if (filteredDocs.isEmpty) return const Center(child: Text("No doctors found"));

        return ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final data = filteredDocs[index].data() as Map<String, dynamic>;
            return _doctorCard(
              filteredDocs[index].id,
              data['fullName'] ?? "Doctor",
              data['specialization'] ?? "Specialist",
              data['profileImage'],
            );
          },
        );
      },
    );
  }

  Widget _doctorCard(String id, String name, String spec, String? image) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorProfilePage(doctorId: id))),
      child: Container(
        width: 290,
        margin: const EdgeInsets.only(right: 15),
        padding: const EdgeInsets.all(15),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            CircleAvatar(
              radius: 35,
              backgroundImage: image != null ? NetworkImage(image) : null,
              backgroundColor: Colors.grey.shade200,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: _titleStyle()),
                  Text(spec, style: _subStyle()),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _tag("Available"),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => BookAppointmentPage(doctorId: id, doctorName: name)),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Book", style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _articleList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("articles").orderBy("createdAt", descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final filtered = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['title'].toString().toLowerCase().contains(articleSearch.toLowerCase());
        }).toList();

        if (filtered.isEmpty) return const Center(child: Text("No articles found"));

        return ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final docId = filtered[index].id;
            final data = filtered[index].data() as Map<String, dynamic>;
            final imageUrl = data['fileUrl'] ?? "";

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ArticleDetailPage(
                      articleId: docId,
                      data: data,
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // <-- fix overflow
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                            child: Image.network(
                              imageUrl,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 150,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.image_not_supported),
                                );
                              },
                            ),
                          )
                        : Container(
                            height: 150,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF1F7F2),
                              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                            child: const Center(child: Icon(Icons.image, size: 50, color: Colors.grey)),
                          ),
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // <-- fix overflow
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['title'] ?? "Article", style: _titleStyle(fontSize: 17)),
                          const SizedBox(height: 8),
                          Text(
                            data['content'] ?? "",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.black54, fontSize: 13),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.grey,
                                child: Icon(Icons.person, size: 16, color: Colors.white),
                              ),
                              const SizedBox(width: 8),
                              Text("${data['author'] ?? 'Dr. Unknown'}",
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              const Spacer(),
                              const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ================= HELPERS =================
  Widget _sectionTitle(String title) =>
      Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryGreen));

  Widget _searchBox(String hint, Function(String) onChanged) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black12)),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _tag(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: const Color(0xFFF1F7F2), borderRadius: BorderRadius.circular(10)),
        child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      );

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      );

  TextStyle _titleStyle({double fontSize = 15}) =>
      TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: secondaryGreen);

  TextStyle _subStyle() => const TextStyle(fontSize: 11, color: Color(0xFF2D6A4F), fontWeight: FontWeight.w600);

  // ================= BOTTOM NAV =================
  Widget _bottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      selectedItemColor: primaryGreen,
      unselectedItemColor: Colors.black38,
      onTap: (i) {
        setState(() => _selectedIndex = i);
        if (i == 3) _openDashboard();
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.book), label: "Learn"),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: "Booking"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
      ],
    );
  }

  void _openDashboard() {
    Widget page;
    switch (widget.role) {
      case 'doctor':
        page = const DoctorDashboard();
        break;
      case 'admin':
        page = const AdminDashboard();
        break;
      default:
        page = const PatientDashboard();
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}
