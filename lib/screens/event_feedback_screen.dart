import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EventFeedbackScreen extends StatelessWidget {
  final String eventId;
  final String eventTitle;
  const EventFeedbackScreen({super.key, required this.eventId, required this.eventTitle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Feedback for "$eventTitle"')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('events')
            .doc(eventId)
            .collection('feedbacks')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No feedback yet.'));
          }
          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: const Icon(Icons.feedback),
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