import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AppFeedbackPage extends StatefulWidget {
  final String role;

  const AppFeedbackPage({super.key, required this.role});

  @override
  State<AppFeedbackPage> createState() => _AppFeedbackPageState();
}

class _AppFeedbackPageState extends State<AppFeedbackPage> {
  final _commentController = TextEditingController();
  int _rating = 0;
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadExistingFeedback();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingFeedback() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final document = await FirebaseFirestore.instance
          .collection('app_feedback')
          .doc(user.uid)
          .get();
      final feedback = document.data();
      if (mounted && feedback != null) {
        setState(() {
          _rating = int.tryParse(feedback['rating']?.toString() ?? '') ?? 0;
          _commentController.text = feedback['comment']?.toString() ?? '';
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load your feedback: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitFeedback() async {
    final user = FirebaseAuth.instance.currentUser;
    final comment = _commentController.text.trim();
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to submit feedback')),
      );
      return;
    }
    if (_rating == 0 || comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose a rating and write your feedback'),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final reference = FirebaseFirestore.instance
          .collection('app_feedback')
          .doc(user.uid);
      final existing = await reference.get();
      await reference.set({
        'userId': user.uid,
        'userName': user.displayName ?? user.email ?? 'App user',
        'role': widget.role,
        'rating': _rating,
        'comment': comment,
        if (!existing.exists) 'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you for your feedback!')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not submit feedback: $error')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App feedback & review')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Icon(
                  Icons.rate_review_outlined,
                  size: 58,
                  color: Color(0xFF24615E),
                ),
                const SizedBox(height: 16),
                const Text(
                  'How are we doing?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Rate your experience and share feedback with our team.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (index) => IconButton(
                      tooltip: '${index + 1} stars',
                      onPressed: () => setState(() => _rating = index + 1),
                      icon: Icon(
                        index < _rating ? Icons.star : Icons.star_border,
                        color: const Color(0xFFC59D3F),
                        size: 36,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _commentController,
                  minLines: 5,
                  maxLines: 8,
                  maxLength: 2000,
                  decoration: const InputDecoration(
                    labelText: 'Your feedback',
                    hintText: 'Tell us what you like or what we can improve',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _submitting ? null : _submitFeedback,
                  icon: _submitting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_outlined),
                  label: Text(_submitting ? 'Submitting...' : 'Submit review'),
                ),
              ],
            ),
    );
  }
}

class AppFeedbackInboxPage extends StatelessWidget {
  const AppFeedbackInboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App feedback')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('app_feedback')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Could not load feedback: ${snapshot.error}'),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final feedback = snapshot.data?.docs ?? [];
          if (feedback.isEmpty) {
            return const Center(child: Text('No app feedback yet'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: feedback.length,
            itemBuilder: (context, index) {
              final entry = feedback[index].data();
              final rating =
                  int.tryParse(entry['rating']?.toString() ?? '') ?? 0;
              final timestamp = entry['createdAt'];
              final date = timestamp is Timestamp
                  ? timestamp.toDate().toLocal().toString().split('.').first
                  : 'Date unavailable';
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry['userName']?.toString() ?? 'App user',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(entry['role']?.toString() ?? 'user'),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          ...List.generate(
                            5,
                            (star) => Icon(
                              star < rating ? Icons.star : Icons.star_border,
                              size: 18,
                              color: const Color(0xFFC59D3F),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(date, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(entry['comment']?.toString() ?? ''),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
