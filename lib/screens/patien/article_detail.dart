import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../doctor/appointment/book_appointment.dart';

class ArticleDetailPage extends StatefulWidget {
  final String articleId;
  final Map<String, dynamic> data;

  const ArticleDetailPage({
    super.key,
    required this.articleId,
    required this.data,
  });

  @override
  State<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage> {
  final Color primaryGreen = const Color(0xFF24615E);
  final Color secondaryGreen = const Color(0xFF1B4332);

  Future<void> _bookAppointment(String doctorName) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('doctors')
        .where('fullName', isEqualTo: doctorName)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Doctor not found")),
        );
      }
      return;
    }

    final doctorId = querySnapshot.docs.first.id;

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookAppointmentPage(
            doctorId: doctorId,
            doctorName: doctorName,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.data['fileUrl'] ?? "";
    final title = widget.data['title'] ?? "Untitled Article";
    final content = widget.data['content'] ?? "";
    final doctorName = widget.data['author'] ?? "Dr. Unknown";
    final specialization = widget.data['specialty'] ?? "Specialist";
    final createdAt = widget.data['createdAt'] as Timestamp;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFB),
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        title: const Text("Article Details"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Article Image
            if (imageUrl.isNotEmpty)
              Image.network(
                imageUrl,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 250,
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(Icons.image_not_supported, size: 80),
                    ),
                  );
                },
              )
            else
              Container(
                height: 250,
                color: Colors.grey.shade200,
                child: const Center(
                  child: Icon(Icons.image, size: 80, color: Colors.grey),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: secondaryGreen,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Doctor Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: primaryGreen.withOpacity(0.2),
                              child: Icon(
                                Icons.person,
                                color: primaryGreen,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    doctorName,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    specialization,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              _bookAppointment(doctorName);
                            },
                            child: const Text(
                              "Book Appointment",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Date
                  Row(
                    children: [
                      Icon(Icons.calendar_today, color: primaryGreen, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        createdAt.toDate().toLocal().toString().split('.')[0],
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Divider
                  Container(
                    height: 1,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 24),

                  // Article Content
                  Text(
                    "Article",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: secondaryGreen,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
