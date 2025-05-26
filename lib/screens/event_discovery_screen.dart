import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventDiscoveryScreen extends StatelessWidget {
  const EventDiscoveryScreen({super.key});

  Future<void> registerForEvent(String eventId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('events')
        .doc(eventId)
        .collection('registrations')
        .doc(user.uid)
        .set({
      'registeredAt': FieldValue.serverTimestamp(),
      'email': user.email,
      'displayName': user.displayName ?? '',
    });
  }

  Future<bool> isRegistered(String eventId, String userId) async {
    final doc = await FirebaseFirestore.instance
        .collection('events')
        .doc(eventId)
        .collection('registrations')
        .doc(userId)
        .get();
    return doc.exists;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Discover Events')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('events')
            .orderBy('date')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No events available.'));
          }
          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final event = docs[index].data() as Map<String, dynamic>;
              final eventId = docs[index].id;
              String dateStr = '';
              if (event['date'] != null) {
                if (event['date'] is Timestamp) {
                  dateStr = (event['date'] as Timestamp)
                      .toDate()
                      .toString()
                      .split(' ')
                      .first;
                } else if (event['date'] is String) {
                  dateStr = event['date'].toString().split('T').first;
                }
              }
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(event['title'] ?? ''),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event['description'] ?? ''),
                      Text('Location: ${event['location'] ?? ''}'),
                      Text('Date: $dateStr'),
                    ],
                  ),
                  trailing: user == null
                      ? null
                      : FutureBuilder<bool>(
                          future: isRegistered(eventId, user.uid),
                          builder: (context, regSnapshot) {
                            if (!regSnapshot.hasData) {
                              return const SizedBox(
                                  width: 100,
                                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
                            }
                            if (regSnapshot.data == true) {
                              return const Text(
                                'Registered',
                                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                              );
                            }
                            return ElevatedButton(
                              onPressed: () => registerForEvent(eventId),
                              child: const Text('Register'),
                            );
                          },
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