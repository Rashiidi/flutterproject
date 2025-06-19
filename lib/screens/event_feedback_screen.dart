import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Screen to show all feedback for a specific event
class EventFeedbackScreen extends StatelessWidget {
  final String eventId;
  final String eventTitle;
  const EventFeedbackScreen({super.key, required this.eventId, required this.eventTitle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Feedback for "$eventTitle"')),
      // Listen to feedbacks for this event in real time
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('events')
            .doc(eventId)
            .collection('feedbacks')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // Show loading spinner while waiting for data
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // If no feedback, show a message
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No feedback yet.'));
          }
          final docs = snapshot.data!.docs;
          // Show each feedback as a ListTile
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: const Icon(Icons.feedback), // You can replace with avatar if you want
                title: Text(data['displayName'] ?? 'Anonymous'),
                subtitle: Text(data['feedback'] ?? ''),
                trailing: Text(
                  data['timestamp'] != null
                      ? (data['timestamp'] as Timestamp)
                          .toDate()
                          .toString()
                          .split(' ')
                          .first
                      : '',
                ),
              );
            },
          );
        },
      ),
    );
  }
}