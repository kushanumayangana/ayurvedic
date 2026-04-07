import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Ensure this path matches your actual file location
import '../doctor/articles/write_article_page.dart';

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

  @override
  void initState() {
    super.initState();
    // Tab controller for Appointments and Articles
    _tabController = TabController(length: 2, vsync: this);
    _fetchDoctorName();
  }

  Future<void> _fetchDoctorName() async {
    final doc = await FirebaseFirestore.instance.collection('doctors').doc(widget.doctorId).get();
    if (doc.exists) {
      setState(() {
        _doctorName = doc.data()?['fullName'] ?? "Doctor";
      });
    }
  }

  // ================= UPDATE STATUS =================
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

  // ================= DELETE APPOINTMENT / ARTICLE =================
  Future<void> _deleteDocument(String collection, String docId) async {
    try {
      await FirebaseFirestore.instance.collection(collection).doc(docId).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${collection == 'articles' ? 'Article' : 'Appointment'} deleted ✅")),
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
            Tab(text: "My Articles", icon: Icon(Icons.article)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAppointmentTab(),
          _buildArticleTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WriteArticlePage(
              doctorId: widget.doctorId,
              doctorName: _doctorName,
            ),
          ),
        ),
        backgroundColor: primaryGreen,
        icon: const Icon(Icons.edit_note, color: Colors.white),
        label: const Text("Write Article", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  // ================= APPOINTMENT TAB (YOUR ORIGINAL VIEW) =================
  Widget _buildAppointmentTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: widget.doctorId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return _emptyState(Icons.event_busy, "No Appointments Found");

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final status = data['status'] ?? 'pending';
            final docId = docs[index].id;
            return _buildAppointmentCard(data, docId, status);
          },
        );
      },
    );
  }

  // ================= ARTICLES TAB =================
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
            final docId = docs[index].id;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(10),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: (data['fileUrl'] != null && data['fileUrl'] != "")
                      ? Image.network(data['fileUrl'], width: 60, height: 60, fit: BoxFit.cover)
                      : Container(color: Colors.grey[200], width: 60, height: 60, child: const Icon(Icons.image)),
                ),
                title: Text(data['title'] ?? "Untitled", style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Published: ${data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate().toString().split(' ')[0] : 'N/A'}"),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () => _deleteDocument('articles', docId),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ================= YOUR ORIGINAL APPOINTMENT CARD =================
  Widget _buildAppointmentCard(Map<String, dynamic> data, String docId, String status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('patients').doc(data['patientId']).get(),
                builder: (context, patientSnapshot) {
                  String displayName = data['patientName'] ?? "New Patient";
                  String imageUrl = data['patientImage'] ?? "";
                  String ageValue = data['patientAge']?.toString() ?? "-";

                  if (patientSnapshot.hasData && patientSnapshot.data!.exists) {
                    final pData = patientSnapshot.data!.data() as Map<String, dynamic>;
                    displayName = pData['name'] ?? displayName;
                    imageUrl = pData['image'] ?? imageUrl;
                    if (pData['age'] != null) ageValue = pData['age'].toString();
                  }

                  return Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: primaryGreen.withOpacity(0.1),
                        backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                        child: imageUrl.isEmpty ? Icon(Icons.person, color: primaryGreen) : null,
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                            Text("Age: $ageValue", style: const TextStyle(color: Color(0xFF757575))),
                          ],
                        ),
                      ),
                      _buildStatusBadge(status),
                    ],
                  );
                },
              ),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              color: accentCloud.withOpacity(0.5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: status == 'pending'
                    ? [
                        _buildActionButton("Reject", Colors.redAccent, () => _updateStatus(docId, 'rejected')),
                        const SizedBox(width: 8),
                        _buildActionButton("Approve", Colors.green, () => _updateStatus(docId, 'approved')),
                      ]
                    : [
                        _buildActionButton("Clear Record", const Color(0xFF607D8B), () => _deleteDocument('appointments', docId)),
                      ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= UI HELPERS =================
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: primaryGreen),
        const SizedBox(width: 10),
        Text("$label: ", style: const TextStyle(fontWeight: FontWeight.w600)),
        Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = status == 'approved' ? Colors.green : (status == 'rejected' ? Colors.red : Colors.orange);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onPressed) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(label),
    );
  }

  Widget _emptyState(IconData icon, String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 10),
          Text(text, style: const TextStyle(color: Color(0xFF757575), fontSize: 18)),
        ],
      ),
    );
  }
}