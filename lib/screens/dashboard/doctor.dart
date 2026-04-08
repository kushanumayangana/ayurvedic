import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../doctor/articles/write_article_page.dart';
import '../doctor/doctor_profile.dart';
import '../marketplace/addproductpage.dart';

class DoctorDashboardPage extends StatefulWidget {
  final String doctorId;
  const DoctorDashboardPage({super.key, required this.doctorId});

  @override
  State<DoctorDashboardPage> createState() => _DoctorDashboardPageState();
}

class _DoctorDashboardPageState extends State<DoctorDashboardPage> with SingleTickerProviderStateMixin {
  final Color primaryGreen = const Color(0xFF24615E);
  final Color accentCloud = const Color(0xFFF1F5F9);
  
  late TabController _tabController;
  String _doctorName = "Doctor";
  String _profileImageUrl = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {}); 
    });
    _fetchDoctorData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchDoctorData() async {
    final doc = await FirebaseFirestore.instance.collection('doctors').doc(widget.doctorId).get();
    if (doc.exists) {
      setState(() {
        _doctorName = doc.data()?['fullName'] ?? "Doctor";
        _profileImageUrl = doc.data()?['profileImage'] ?? "";
      });
    }
  }

  Future<void> _updateStatus(String docId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(docId)
          .update({'status': status});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Appointment $status ✅"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: status == 'approved' ? Colors.green : Colors.redAccent,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Update failed: $e")),
      );
    }
  }

  Future<void> _deleteDocument(String collection, String docId) async {
    try {
      await FirebaseFirestore.instance.collection(collection).doc(docId).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Deleted successfully ✅"), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Delete failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.doctorId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("Error: No Doctor ID provided.")),
      );
    }

    return Scaffold(
      backgroundColor: accentCloud,
      appBar: AppBar(
        title: const Text(
          "Doctor Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        elevation: 0,
        centerTitle: true,
        backgroundColor: primaryGreen,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: "Appointments", icon: Icon(Icons.calendar_today)),
            Tab(text: "Articles", icon: Icon(Icons.article)),
            Tab(text: "My Shop", icon: Icon(Icons.storefront)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAppointmentTab(),
          _buildArticleTab(),
          _buildShopTab(), 
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildFab() {
    bool isShop = _tabController.index == 2;
    return FloatingActionButton.extended(
      onPressed: () {
        if (isShop) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => AddProductPage(doctorId: widget.doctorId)));
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WriteArticlePage(
                doctorId: widget.doctorId,
                doctorName: _doctorName,
              ),
            ),
          );
        }
      },
      backgroundColor: primaryGreen,
      icon: Icon(isShop ? Icons.add_shopping_cart : Icons.edit_note, color: Colors.white),
      label: Text(isShop ? "Add Product" : "Write Article", style: const TextStyle(color: Colors.white)),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: primaryGreen.withOpacity(0.1),
            backgroundImage: _profileImageUrl.isNotEmpty ? NetworkImage(_profileImageUrl) : null,
            child: _profileImageUrl.isEmpty ? Icon(Icons.person, color: primaryGreen, size: 30) : null,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Welcome, $_doctorName", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const Text("Manage your profile and schedule", style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DoctorProfilePage(doctorId: widget.doctorId)),
              ).then((_) => _fetchDoctorData()); 
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Edit"),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: widget.doctorId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data?.docs ?? [];
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) return _buildProfileHeader(); 
            final data = docs[index - 1].data() as Map<String, dynamic>;
            return _buildAppointmentCard(data, docs[index - 1].id, data['status'] ?? 'pending');
          },
        );
      },
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> data, String docId, String status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('patients').doc(data['patientId']).get(),
              builder: (context, patientSnapshot) {
                String patientName = data['patientName'] ?? "Patient";
                String patientImage = "";
                String patientAge = data['patientAge']?.toString() ?? "-";

                if (patientSnapshot.hasData && patientSnapshot.data!.exists) {
                  final pData = patientSnapshot.data!.data() as Map<String, dynamic>;
                  patientName = pData['name'] ?? patientName;
                  patientImage = pData['image'] ?? "";
                  patientAge = pData['age']?.toString() ?? patientAge;
                }

                return Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: primaryGreen.withOpacity(0.1),
                      backgroundImage: patientImage.isNotEmpty ? NetworkImage(patientImage) : null,
                      child: patientImage.isEmpty ? Icon(Icons.person, color: primaryGreen) : null,
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(patientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text("Age: $patientAge", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    _buildStatusBadge(status),
                  ],
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(Icons.calendar_today, "Date", data['date'] ?? '-'),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.access_time, "Time", data['time'] ?? '-'),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.notes, "Reason", data['reason'] ?? 'No description'),
              ],
            ),
          ),
          if (status == 'pending')
            Padding(
              padding: const EdgeInsets.only(bottom: 12, right: 12),
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                _buildActionButton("Reject", Colors.redAccent, () => _updateStatus(docId, 'rejected')),
                const SizedBox(width: 8),
                _buildActionButton("Approve", Colors.green, () => _updateStatus(docId, 'approved')),
              ]),
            ),
        ],
      ),
    );
  }

  Widget _buildArticleTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('articles')
          .where('doctorId', isEqualTo: widget.doctorId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return _emptyState(Icons.note_alt_outlined, "No articles published yet");

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: (data['fileUrl'] != null && data['fileUrl'] != "")
                      ? Image.network(data['fileUrl'], width: 50, height: 50, fit: BoxFit.cover)
                      : Container(color: Colors.grey[200], width: 50, height: 50, child: const Icon(Icons.image)),
                ),
                title: Text(data['title'] ?? "Untitled", style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _deleteDocument('articles', docs[index].id)),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildShopTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('doctorId', isEqualTo: widget.doctorId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return _emptyState(Icons.storefront, "Your shop is currently empty.");

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _buildProductCard(data, docs[index].id);
          },
        );
      },
    );
  }

  Widget _buildProductCard(Map<String, dynamic> data, String docId) {
    // UPDATED: Logic to specifically handle the multi-image array
    List<String> images = [];
    if (data['imageUrls'] != null && data['imageUrls'] is List) {
      images = List<String>.from(data['imageUrls'].map((item) => item.toString()));
    } else if (data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty) {
      images = [data['imageUrl'].toString()];
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 240,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: images.isNotEmpty
                      ? PageView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: images.length,
                          itemBuilder: (context, i) => Image.network(
                            images[i],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            loadingBuilder: (context, child, progress) => progress == null ? child : Center(child: CircularProgressIndicator(color: primaryGreen.withOpacity(0.2))),
                            errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image, color: Colors.grey)),
                          ),
                        )
                      : Container(color: Colors.grey[100], child: const Center(child: Icon(Icons.image_not_supported))),
                ),
                
                if (images.length > 1)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                      child: Text("${images.length} Photos", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),

                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () => _deleteDocument('products', docId),
                    child: CircleAvatar(backgroundColor: Colors.white.withOpacity(0.9), radius: 18, child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20)),
                  ),
                ),

                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: primaryGreen, borderRadius: BorderRadius.circular(8)),
                    child: Text(data['category']?.toUpperCase() ?? "NEW", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(data['title'] ?? "Product", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), overflow: TextOverflow.ellipsis)),
                    Text("LKR ${data['price']}", style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w900, fontSize: 18)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(data['description'] ?? "", style: TextStyle(color: Colors.grey[600], fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 10),
                Text("Stock: ${data['stock'] ?? 0}", style: TextStyle(color: primaryGreen, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(children: [Icon(icon, size: 16, color: primaryGreen), const SizedBox(width: 10), Text("$label: $value")]);
  }

  Widget _buildStatusBadge(String status) {
    Color color = status == 'approved' ? Colors.green : (status == 'rejected' ? Colors.red : Colors.orange);
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)));
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onPressed) {
    return ElevatedButton(onPressed: onPressed, style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: Text(label));
  }

  Widget _emptyState(IconData icon, String text) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 60, color: Colors.grey[300]), Text(text, style: const TextStyle(color: Colors.grey))]));
  }
}