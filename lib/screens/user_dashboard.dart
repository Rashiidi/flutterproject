import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'event_discovery_screen.dart';

class UserHome extends StatefulWidget {
  const UserHome({super.key});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  Future<List<Map<String, dynamic>>> fetchRegisteredEvents() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final eventsSnapshot = await FirebaseFirestore.instance.collection('events').get();
    List<Map<String, dynamic>> registeredEvents = [];

    for (var doc in eventsSnapshot.docs) {
      final registration = await doc.reference
          .collection('registrations')
          .doc(user.uid)
          .get();
      if (registration.exists) {
        final eventData = doc.data();
        eventData['id'] = doc.id;
        registeredEvents.add(eventData);
      }
    }
    return registeredEvents;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Home"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EventDiscoveryScreen()),
              );
            },
            child: const Text('Discover Events'),
          ),
          const SizedBox(height: 24),
          const Text(
            'Your Registered Events',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchRegisteredEvents(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No registered events.'));
                }
                final events = snapshot.data!;
                return ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
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
                        subtitle: Text(event['description'] ?? ''),
                        trailing: Text(dateStr),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}