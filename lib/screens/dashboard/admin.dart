import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../admin/doctor_approval_list.dart';
import '../admin/seller_approval_list.dart';
import '../marketplace/app_feedback_page.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  static const Color primaryBlue = Color(0xFF1D2671);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: primaryBlue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const Text(
              'Approvals',
              style: TextStyle(
                color: Color(0xFF20283A),
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final doctorCard = _ApprovalCard(
                  title: 'Doctor approvals',
                  description: 'Review healthcare professional applications',
                  collection: 'doctors',
                  icon: Icons.medical_services_outlined,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DoctorApprovalList(),
                    ),
                  ),
                );
                final sellerCard = _ApprovalCard(
                  title: 'Seller approvals',
                  description: 'Review seller and shop applications',
                  collection: 'sellers',
                  icon: Icons.storefront_outlined,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SellerApprovalList(),
                    ),
                  ),
                );

                if (constraints.maxWidth < 620) {
                  return Column(
                    children: [
                      doctorCard,
                      const SizedBox(height: 12),
                      sellerCard,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: doctorCard),
                    const SizedBox(width: 14),
                    Expanded(child: sellerCard),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.amber.withValues(alpha: 0.2),
                  child: const Icon(
                    Icons.rate_review_outlined,
                    color: Colors.amber,
                  ),
                ),
                title: const Text(
                  "App Feedback & Reviews",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text("Read ratings and feedback from users"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AppFeedbackInboxPage(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            const _QuickSummary(),
          ],
        ),
      ),
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  const _ApprovalCard({
    required this.title,
    required this.description,
    required this.collection,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String description;
  final String collection;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(collection)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        final hasError = snapshot.hasError;
        final isLoading = !snapshot.hasData && !hasError;
        final pendingCount = snapshot.data?.docs.length;

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE8ECF5)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D1D2671),
                    blurRadius: 18,
                    offset: Offset(0, 7),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: AdminDashboard.primaryBlue.withValues(
                              alpha: 0.09,
                            ),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(
                            icon,
                            color: AdminDashboard.primaryBlue,
                            size: 23,
                          ),
                        ),
                        const Spacer(),
                        if (isLoading)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AdminDashboard.primaryBlue,
                            ),
                          )
                        else if (hasError)
                          const Icon(
                            Icons.error_outline_rounded,
                            color: Color(0xFFC14848),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: pendingCount == 0
                                  ? const Color(0xFFEAF6F0)
                                  : const Color(0xFFFFF3E5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$pendingCount pending',
                              style: TextStyle(
                                color: pendingCount == 0
                                    ? const Color(0xFF27845B)
                                    : const Color(0xFF9B5B13),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 17),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF20283A),
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      hasError
                          ? 'Pending applications could not be loaded.'
                          : description,
                      style: TextStyle(
                        color: hasError
                            ? const Color(0xFFC14848)
                            : const Color(0xFF778197),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Text(
                          'Open applications',
                          style: TextStyle(
                            color: AdminDashboard.primaryBlue,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: AdminDashboard.primaryBlue,
                          size: 17,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _QuickSummary extends StatelessWidget {
  const _QuickSummary();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Color(0xFFE8ECF5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AdminDashboard.primaryBlue.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.insights_rounded,
                    color: AdminDashboard.primaryBlue,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Quick Summary",
                        style: TextStyle(
                          color: Color(0xFF20283A),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        "Live registration and approval status",
                        style: TextStyle(
                          color: Color(0xFF778197),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.circle, color: Color(0xFF36A675), size: 9),
                const SizedBox(width: 6),
                const Text(
                  "LIVE",
                  style: TextStyle(
                    color: Color(0xFF36A675),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('doctors')
                  .snapshots(),
              builder: (context, doctorSnapshot) {
                if (doctorSnapshot.hasError) {
                  return _SummaryError(error: doctorSnapshot.error);
                }
                if (!doctorSnapshot.hasData) {
                  return const _SummaryLoading();
                }

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('sellers')
                      .snapshots(),
                  builder: (context, sellerSnapshot) {
                    if (sellerSnapshot.hasError) {
                      return _SummaryError(error: sellerSnapshot.error);
                    }
                    if (!sellerSnapshot.hasData) {
                      return const _SummaryLoading();
                    }

                    final doctors = _RegistrationCounts.fromDocuments(
                      doctorSnapshot.data!.docs,
                    );
                    final sellers = _RegistrationCounts.fromDocuments(
                      sellerSnapshot.data!.docs,
                    );

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final doctorCard = _SummaryEntityCard(
                          title: 'Doctors',
                          icon: Icons.medical_services_outlined,
                          accent: AdminDashboard.primaryBlue,
                          counts: doctors,
                        );
                        final sellerCard = _SummaryEntityCard(
                          title: 'Sellers',
                          icon: Icons.storefront_outlined,
                          accent: const Color(0xFF5268B8),
                          counts: sellers,
                        );

                        if (constraints.maxWidth < 560) {
                          return Column(
                            children: [
                              doctorCard,
                              const SizedBox(height: 12),
                              sellerCard,
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: doctorCard),
                            const SizedBox(width: 12),
                            Expanded(child: sellerCard),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RegistrationCounts {
  const _RegistrationCounts({
    required this.total,
    required this.approved,
    required this.pending,
    required this.rejected,
    required this.other,
  });

  final int total;
  final int approved;
  final int pending;
  final int rejected;
  final int other;

  factory _RegistrationCounts.fromDocuments(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    var approved = 0;
    var pending = 0;
    var rejected = 0;
    var other = 0;

    for (final document in documents) {
      final rawStatus = document.data()['status'];
      final status = rawStatus is String && rawStatus.trim().isNotEmpty
          ? rawStatus.trim().toLowerCase()
          : 'pending';

      switch (status) {
        case 'approved':
          approved++;
        case 'rejected':
          rejected++;
        case 'pending':
          pending++;
        default:
          other++;
      }
    }

    return _RegistrationCounts(
      total: documents.length,
      approved: approved,
      pending: pending,
      rejected: rejected,
      other: other,
    );
  }
}

class _SummaryEntityCard extends StatelessWidget {
  const _SummaryEntityCard({
    required this.title,
    required this.icon,
    required this.accent,
    required this.counts,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final _RegistrationCounts counts;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFEDF0F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 19),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF454E62),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${counts.total}',
            style: const TextStyle(
              color: Color(0xFF20283A),
              fontSize: 32,
              height: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Registered',
            style: TextStyle(color: Color(0xFF778197), fontSize: 12),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _StatusCount(
                label: 'Approved',
                count: counts.approved,
                color: const Color(0xFF27845B),
              ),
              _StatusCount(
                label: 'Pending',
                count: counts.pending,
                color: const Color(0xFFB7791F),
              ),
              _StatusCount(
                label: 'Rejected',
                count: counts.rejected,
                color: const Color(0xFFC14848),
              ),
              if (counts.other > 0)
                _StatusCount(
                  label: 'Other',
                  count: counts.other,
                  color: const Color(0xFF687386),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusCount extends StatelessWidget {
  const _StatusCount({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        '$label $count',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SummaryLoading extends StatelessWidget {
  const _SummaryLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 22),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AdminDashboard.primaryBlue,
          ),
        ),
      ),
    );
  }
}

class _SummaryError extends StatelessWidget {
  const _SummaryError({required this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Unable to load registration summary. ${error ?? ''}',
        style: const TextStyle(color: Color(0xFF9B3535), fontSize: 13),
      ),
    );
  }
}
