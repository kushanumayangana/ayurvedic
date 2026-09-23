import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Screens
import '../doctor/appointment/book_appointment.dart';
import '../doctor/doctor_login.dart';
import '../doctor/doctor_profile.dart';
import '../doctor/articles/article_detail.dart';
import '../marketplace/product_detail_page.dart';

// Dashboard imports with prefixes
import '../dashboard/doctor.dart' as doctor;
import '../dashboard/patient.dart' as patient;
import '../dashboard/admin.dart' as admin;

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
                    // --- DOCTOR SECTION ---
                    _sectionTitle("Doctor Channeling"),
                    const SizedBox(height: 15),
                    _searchBox("Search doctors...",
                        (value) => setState(() => doctorSearch = value)),
                    const SizedBox(height: 15),
                    SizedBox(height: 180, child: _doctorList()),
                    
                    const SizedBox(height: 35),

                    // --- MARKETPLACE SECTION (NEW) ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _sectionTitle("Market Place"),
                        Text("View All", style: TextStyle(color: primaryGreen, fontSize: 12)),
                      ],
                    ),
                    const Text("Popular Medicines", style: TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 15),
                    SizedBox(height: 220, child: _marketPlaceList()),

                    const SizedBox(height: 35),

                    // --- LEARN HUB SECTION ---
                    _sectionTitle("Learn Hub"),
                    const SizedBox(height: 15),
                    _searchBox("Search articles...",
                        (value) => setState(() => articleSearch = value)),
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

  // ================= DYNAMIC HEADER =================
  Widget _buildHeader() {
    // Determine the name to display based on the role
    String displayName;
    if (widget.role.toLowerCase() == 'doctor') {
      displayName = "Doctor";
    } else if (widget.role.toLowerCase() == 'admin') {
      displayName = "Admin";
    } else {
      // Use the user's name from Firebase if it exists, otherwise 'User'
      displayName = user?.displayName ?? 'User';
    }

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
                const Text("AyurvedaCare",
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                // UPDATED: Dynamic Greeting based on Role
                Text("Hello, $displayName",
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: secondaryGreen)),
                const SizedBox(height: 5),
                const Text("How are you feeling today?",
                    style: TextStyle(color: Color(0xFF6A9175))),
              ],
            ),
          ),
          IconButton(
            onPressed: _openDashboard,
            icon: Icon(Icons.dashboard, color: primaryGreen),
          ),
        ],
      ),
    );
  }

  // ================= MARKETPLACE LIST =================
  Widget _marketPlaceList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("products").snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final products = snapshot.data!.docs;

        if (products.isEmpty) {
          return const Center(child: Text("No products available"));
        }

        return ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: products.length,
          itemBuilder: (context, index) {
            final data = products[index].data() as Map<String, dynamic>;
            return _productCard(
              data['title'] ?? "Product",
              data['category'] ?? "General",
              data['price']?.toString() ?? "0",
              data['imageUrl'] ?? (data['imageUrls'] != null ? data['imageUrls'][0] : ""),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductDetailPage(product: data),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _productCard(String title, String category, String price, String image, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 15),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      image: image.isNotEmpty 
                        ? DecorationImage(image: NetworkImage(image), fit: BoxFit.cover)
                        : null,
                      color: Colors.grey.shade100,
                    ),
                    child: image.isEmpty ? const Center(child: Icon(Icons.medication)) : null,
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryGreen.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        category.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: _titleStyle().copyWith(fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(category, style: _subStyle()),
                  const SizedBox(height: 5),
                  Text("LKR $price", style: TextStyle(fontWeight: FontWeight.bold, color: primaryGreen)),
                ],
              ),
            ),
          ],
        ),
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
              backgroundImage: (image != null && image.isNotEmpty) ? NetworkImage(image) : null,
              backgroundColor: Colors.grey.shade200,
              child: (image == null || image.isEmpty) ? const Icon(Icons.person) : null,
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
                          MaterialPageRoute(
                            builder: (_) => BookAppointmentPage(doctorId: id, doctorName: name),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
                        child: const Text("Book", style: TextStyle(fontSize: 11, color: Colors.white)),
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
            final String? doctorPic = data['doctorImage'];

            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ArticleDetailPage(articleId: docId, data: data),
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: _cardDecoration(),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: (doctorPic != null && doctorPic.isNotEmpty) ? NetworkImage(doctorPic) : null,
                      child: (doctorPic == null || doctorPic.isEmpty) ? const Icon(Icons.person, color: Colors.grey) : null,
                    ),
                    title: Text(data['title'] ?? "Article", style: _titleStyle().copyWith(fontSize: 18)),
                    subtitle: Text("By ${data['author'] ?? 'Unknown'}", style: _subStyle()),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ================= HELPERS & BOTTOM NAV =================
  Widget _sectionTitle(String title) => Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryGreen));

  Widget _searchBox(String hint, Function(String) onChanged) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _tag(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(5)),
    child: Text(text, style: const TextStyle(fontSize: 10, color: Colors.green)),
  );

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
  );

  TextStyle _titleStyle() => TextStyle(fontWeight: FontWeight.bold, color: secondaryGreen, fontSize: 16);
  TextStyle _subStyle() => const TextStyle(fontSize: 12, color: Colors.grey);

  Widget _bottomNav() {
    final isDoctor = widget.role.toLowerCase() == 'doctor';

    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: primaryGreen,
      unselectedItemColor: Colors.grey,
      onTap: (i) {
        setState(() => _selectedIndex = i);
        if (i == 3) {
          if (isDoctor) {
            _logoutDoctor();
          } else {
            _openDashboard();
          }
        }
      },
      items: [
        const BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        const BottomNavigationBarItem(icon: Icon(Icons.shop), label: "Shop"),
        const BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: "Booking"),
        BottomNavigationBarItem(
          icon: Icon(isDoctor ? Icons.logout : Icons.person),
          label: isDoctor ? "Logout" : "Profile",
        ),
      ],
    );
  }

  Future<void> _logoutDoctor() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DoctorLoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }

  void _openDashboard() {
    Widget page;
    switch (widget.role) {
      case 'doctor':
        page = doctor.DoctorDashboardPage(doctorId: user?.uid ?? '');
        break;
      case 'admin':
        page = admin.AdminDashboard();
        break;
      default:
        page = patient.PatientDashboardPage();
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}