import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookAppointmentPage extends StatefulWidget {
  final String doctorId;
  final String doctorName;
  final String? sellerId;
  final String? sellerName;
  final String? productTitle;

  const BookAppointmentPage({
    super.key,
    required this.doctorId,
    required this.doctorName,
    this.sellerId,
    this.sellerName,
    this.productTitle,
  });

  @override
  State<BookAppointmentPage> createState() => _BookAppointmentPageState();
}

class _BookAppointmentPageState extends State<BookAppointmentPage> {
  final dateController = TextEditingController();
  final timeController = TextEditingController();
  final reasonController = TextEditingController();
  bool loading = false;

  bool get isSellerBooking => widget.sellerId?.isNotEmpty == true;
  Color get primaryColor => isSellerBooking
      ? const Color(0xFFC59D3F)
      : const Color(0xFF24615E);

  @override
  void dispose() {
    dateController.dispose();
    timeController.dispose();
    reasonController.dispose();
    super.dispose();
  }

  Future<void> pickDate() async {
    DateTime now = DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );
    if (pickedDate != null) {
      dateController.text =
          "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
    }
  }

  Future<void> pickTime() async {
    final TimeOfDay now = TimeOfDay.now();
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: now,
    );
    if (pickedTime != null) {
      timeController.text =
          "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}";
    }
  }

  // ================= UPDATED BOOKING LOGIC =================
  Future<void> bookAppointment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (dateController.text.isEmpty || timeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select both date and time")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      String requesterName = user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : user.email?.split('@').first ?? 'User';
      String requesterRole = 'user';
      String requesterId = user.uid;
      String pAge = "-";
      String requesterImage = '';
      String requesterPhone = '';
      String requesterEmail = user.email ?? '';

      for (final collection in ['sellers', 'doctors', 'patients']) {
        try {
          final profile = await FirebaseFirestore.instance.collection(collection).doc(user.uid).get();
          if (!profile.exists) continue;

          final data = profile.data() ?? <String, dynamic>{};
          final nameFields = collection == 'sellers'
              ? [data['fullName'], data['ownerName'], data['businessName']]
              : collection == 'doctors'
                  ? [data['fullName'], data['name']]
                  : [data['name'], data['fullName']];
          requesterName = nameFields
              .map((value) => value?.toString().trim() ?? '')
              .firstWhere((value) => value.isNotEmpty, orElse: () => requesterName);
          requesterRole = collection == 'patients' ? 'patient' : collection.substring(0, collection.length - 1);
          requesterId = user.uid;
          requesterImage = (data['profileImage'] ?? data['image'] ?? data['imageUrl'] ?? data['profilePic'] ?? '').toString();
          requesterPhone = data['phone']?.toString() ?? '';
          requesterEmail = data['email']?.toString() ?? user.email ?? '';
          if (requesterRole == 'patient') pAge = data['age']?.toString() ?? '-';
          break;
        } catch (_) {
          continue;
        }
      }

      // 2. SAVE APPOINTMENT WITH FULL DETAILS
      await FirebaseFirestore.instance.collection('appointments').add({
        'bookingType': isSellerBooking ? 'seller' : 'doctor',
        'doctorId': isSellerBooking ? '' : widget.doctorId,
        'doctorName': widget.doctorName,
        'sellerId': widget.sellerId ?? '',
        'sellerName': widget.sellerName ?? '',
        'productTitle': widget.productTitle ?? '',
        'patientId': user.uid,
        'requesterId': requesterId,
        'patientName': requesterName,
        'requesterName': requesterName,
        'requesterRole': requesterRole,
        'requesterImage': requesterImage,
        'requesterPhone': requesterPhone,
        'requesterEmail': requesterEmail,
        'patientAge': pAge,
        'patientImage': requesterImage,
        'patientEmail': requesterEmail,
        'date': dateController.text,
        'time': timeController.text,
        'reason': reasonController.text.trim(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isSellerBooking
              ? "Booking request sent ✅"
              : "Appointment booked successfully ✅"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, true);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipientName = isSellerBooking
        ? (widget.sellerName?.isNotEmpty == true ? widget.sellerName! : 'Seller')
        : widget.doctorName;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F6),
      appBar: AppBar(
        title: Text(isSellerBooking ? "Request a Booking" : "Book Appointment"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isSellerBooking ? Icons.storefront : Icons.medical_services,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      recipientName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.productTitle?.isNotEmpty == true) ...[
                      const SizedBox(height: 5),
                      Text(
                        widget.productTitle!,
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 26),
              const Text(
                'Choose a time',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _bookingChoice(
                      icon: Icons.calendar_month,
                      label: 'Date',
                      value: dateController.text,
                      onTap: pickDate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _bookingChoice(
                      icon: Icons.schedule,
                      label: 'Time',
                      value: timeController.text,
                      onTap: pickTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Add a note',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: isSellerBooking
                      ? 'What would you like to discuss or arrange?'
                      : 'Tell the doctor what you need help with',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 58),
                    child: Icon(Icons.notes_outlined),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: loading ? null : bookAppointment,
                  icon: loading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(isSellerBooking ? 'Send booking request' : 'Confirm appointment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bookingChoice({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        constraints: const BoxConstraints(minHeight: 86),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, color: primaryColor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 5),
                  Text(value.isEmpty ? 'Select' : value, style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}