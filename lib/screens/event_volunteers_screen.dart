import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EventVolunteersScreen extends StatelessWidget {
  final String eventId;
  final String eventTitle;
  const EventVolunteersScreen({super.key, required this.eventId, required this.eventTitle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Volunteers for "$eventTitle"')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('events')
            .doc(eventId)
            .collection('registrations')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No volunteers registered.'));
          }
          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(data['displayName'] ?? 'No Name'),
                subtitle: Text(data['email'] ?? ''),
                trailing: Text(
                  data['registeredAt'] != null
                      ? (data['registeredAt'] as Timestamp)
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