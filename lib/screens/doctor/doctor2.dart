import 'package:flutter/material.dart';
import 'doctor3.dart';
import '../../constants/colors.dart';

class DoctorRegisterStep2 extends StatefulWidget {
  final String uid, fullName, nic, email;

  const DoctorRegisterStep2({
    super.key,
    required this.uid,
    required this.fullName,
    required this.nic,
    required this.email,
  });

  @override
  State<DoctorRegisterStep2> createState() => _DoctorRegisterStep2State();
}

class _DoctorRegisterStep2State extends State<DoctorRegisterStep2> {
  final TextEditingController regNo = TextEditingController();
  final TextEditingController clinic = TextEditingController();
  String specialization = "Panchakarma";

  // Colors consistent with Step 1
  final Color headerBgColor = const Color(0xFFE9EFEE);
  final Color darkGreen = const Color(0xFF1E5653);
  final Color primaryGreen = const Color(0xFF24615E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- Header Section ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(left: 24, right: 24, top: 60, bottom: 40),
              decoration: BoxDecoration(
                color: headerBgColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: darkGreen),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Text("Professional Info",
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: darkGreen)),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 48.0),
                    child: Text("Step 2 of 3 • Clinic Details",
                        style: TextStyle(color: darkGreen.withOpacity(0.7), fontSize: 14)),
                  ),
                ],
              ),
            ),

            // --- Form Card ---
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Registration No
                    field("Registration No", regNo, Icons.assignment_ind_outlined),

                    const Text("Specialization", 
                        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blueGrey, fontSize: 13)),
                    const SizedBox(height: 8),
                    
                    // Styled Dropdown
                    DropdownButtonFormField<String>(
                      value: specialization,
                      items: const [
                        DropdownMenuItem(value: "Panchakarma", child: Text("Panchakarma")),
                        DropdownMenuItem(value: "Ayurvedic Physician", child: Text("Ayurvedic Physician")),
                        DropdownMenuItem(value: "Herbal Specialist", child: Text("Herbal Specialist")),
                      ],
                      onChanged: (v) => setState(() => specialization = v!),
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.psychology_outlined, color: Colors.grey.shade400),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryGreen, width: 1.5),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Clinic Address
                    field("Clinic Address", clinic, Icons.location_on_outlined),

                    const SizedBox(height: 20),

                    // Next Step Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                          shadowColor: primaryGreen.withOpacity(0.4),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DoctorRegisterStep3(
                                uid: widget.uid,
                                fullName: widget.fullName,
                                nic: widget.nic,
                                email: widget.email,
                                regNo: regNo.text,
                                specialization: specialization,
                                clinicAddress: clinic.text,
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          "Continue to Step 3",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget field(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.blueGrey, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: "Enter $label",
            prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryGreen, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}