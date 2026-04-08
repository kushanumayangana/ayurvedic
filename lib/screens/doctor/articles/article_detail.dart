import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Screens
import '../doctor_profile.dart';
import '../appointment/book_appointment.dart';

class ArticleDetailPage extends StatelessWidget {
  final String articleId;
  final Map<String, dynamic> data;

  const ArticleDetailPage({
    super.key,
    required this.articleId,
    required this.data,
  });

  final Color primaryGreen = const Color(0xFF24615E);
  final Color secondaryGreen = const Color(0xFF1B4332);
  final Color lightBg = const Color(0xFFF9FBFB);

  @override
  Widget build(BuildContext context) {
    // --- Database Field Mapping ---
    final String title = data['title'] ?? 'No Title';
    final String content = data['content'] ?? 'No Content Available';
    final String author = data['author'] ?? 'Unknown Author';
    final String doctorId = data['doctorId'] ?? '';
    
    // Check both potential field names for the doctor's photo
    final String? doctorPic = data['doctorImage'] ?? data['profileImage']; 
    
    // Matches 'fileUrl' from your article document
    final String? articleImg = data['fileUrl']; 
    
    String formattedDate = "";
    if (data['createdAt'] != null) {
      DateTime dt = (data['createdAt'] as Timestamp).toDate();
      formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(dt);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: secondaryGreen,
        elevation: 0,
        title: const Text("Article Details", 
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. Main Article Image ---
            if (articleImg != null && articleImg.isNotEmpty)
              Image.network(
                articleImg,
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 250,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 200,
                color: Colors.grey.shade200,
                child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
              ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 2. Title & Date ---
                  Text(
                    title,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: secondaryGreen),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.calendar_month, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 5),
                      Text(formattedDate, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    ],
                  ),
                  
                  const SizedBox(height: 30),
                  const Text("Article Content", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  // --- 3. Content Body ---
                  Text(
                    content,
                    style: const TextStyle(fontSize: 16, height: 1.7, color: Colors.black87),
                  ),
                  
                  const SizedBox(height: 40),
                  const Divider(),
                  const SizedBox(height: 20),

                  // --- 4. Doctor Info Card ---
                  const Text("Written By", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: lightBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // CLICKABLE PROFILE PHOTO to open DoctorProfilePage
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => DoctorProfilePage(doctorId: doctorId)),
                              ),
                              child: CircleAvatar(
                                radius: 32,
                                backgroundColor: Colors.white,
                                backgroundImage: (doctorPic != null && doctorPic.isNotEmpty)
                                    ? NetworkImage(doctorPic)
                                    : null,
                                child: (doctorPic == null || doctorPic.isEmpty)
                                    ? const Icon(Icons.person, size: 30)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    author,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: secondaryGreen),
                                  ),
                                  const Text("Specialist Physician", style: TextStyle(fontSize: 13, color: Colors.grey)),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => DoctorProfilePage(doctorId: doctorId)),
                              ),
                              icon: Icon(Icons.arrow_forward_ios, size: 18, color: primaryGreen),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // --- 5. Booking Action ---
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BookAppointmentPage(
                                  doctorId: doctorId,
                                  doctorName: author,
                                ),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text(
                              "Book Appointment Now",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                        ),
                      ],
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