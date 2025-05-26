import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'event_discovery_screen.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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
        // Add attended status for certificate logic
        eventData['attended'] = registration.data()?['attended'] == true;
        eventData['duration'] = eventData['duration'] ?? 1;
        registeredEvents.add(eventData);
      }
    }
    return registeredEvents;
  }

  Future<Map<String, dynamic>?> fetchUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Volunteer Dashboard"),
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
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Volunteer Profile Section
          FutureBuilder<Map<String, dynamic>?>(
            future: fetchUserProfile(),
            builder: (context, snapshot) {
              final profile = snapshot.data;
              final hours = profile?['serviceHours'] ?? 0;
              return Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 28,
                        child: Icon(Icons.person, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.displayName ?? 'No Name',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(user?.email ?? ''),
                            const SizedBox(height: 8),
                            Text(
                              'Service Hours: ${hours.toStringAsFixed(1)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                if (hours >= 100) ...[
                                  const Icon(Icons.emoji_events, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  const Text('Gold Badge'),
                                  const SizedBox(width: 16),
                                ] else if (hours >= 50) ...[
                                  const Icon(Icons.emoji_events, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  const Text('Silver Badge'),
                                  const SizedBox(width: 16),
                                ] else if (hours >= 10) ...[
                                  const Icon(Icons.emoji_events, color: Colors.brown),
                                  const SizedBox(width: 4),
                                  const Text('Bronze Badge'),
                                  const SizedBox(width: 16),
                                ] else ...[
                                  const Icon(Icons.emoji_events_outlined, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  const Text('No Badge Yet'),
                                  const SizedBox(width: 16),
                                ],
                                const Icon(Icons.workspace_premium, color: Colors.blue),
                                const SizedBox(width: 4),
                                const Text('Certificates: Download below'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
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
                    final attended = event['attended'] == true;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(event['title'] ?? ''),
                        subtitle: Text(event['description'] ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(dateStr),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () async {
                                final feedback = await showDialog<String>(
                                  context: context,
                                  builder: (context) {
                                    final ctrl = TextEditingController();
                                    return AlertDialog(
                                      title: const Text('Leave Feedback'),
                                      content: TextField(
                                        controller: ctrl,
                                        decoration: const InputDecoration(labelText: 'Your feedback'),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, null),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, ctrl.text.trim()),
                                          child: const Text('Submit'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                                if (feedback != null && feedback.isNotEmpty) {
                                  final user = FirebaseAuth.instance.currentUser;
                                  await FirebaseFirestore.instance
                                      .collection('events')
                                      .doc(event['id'])
                                      .collection('feedbacks')
                                      .doc(user!.uid)
                                      .set({
                                    'feedback': feedback,
                                    'userId': user.uid,
                                    'displayName': user.displayName ?? '',
                                    'email': user.email,
                                    'timestamp': FieldValue.serverTimestamp(),
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Feedback submitted!')),
                                  );
                                }
                              },
                              child: const Text('Leave Feedback'),
                            ),
                            if (attended) ...[
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () async {
                                  final pdf = pw.Document();
                                  pdf.addPage(
                                    pw.Page(
                                      build: (pw.Context context) {
                                        return pw.Center(
                                          child: pw.Column(
                                            mainAxisAlignment: pw.MainAxisAlignment.center,
                                            children: [
                                              pw.Text('Certificate of Participation', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold)),
                                              pw.SizedBox(height: 32),
                                              pw.Text('This certifies that', style: pw.TextStyle(fontSize: 18)),
                                              pw.SizedBox(height: 12),
                                              pw.Text(user?.displayName ?? 'Volunteer', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                                              pw.SizedBox(height: 12),
                                              pw.Text('participated in', style: pw.TextStyle(fontSize: 18)),
                                              pw.SizedBox(height: 12),
                                              pw.Text(event['title'] ?? '', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                                              pw.SizedBox(height: 12),
                                              pw.Text('on $dateStr', style: pw.TextStyle(fontSize: 16)),
                                              pw.SizedBox(height: 12),
                                              pw.Text('and served for ${event['duration'] ?? "N/A"} hour(s).', style: pw.TextStyle(fontSize: 16)),
                                              pw.SizedBox(height: 32),
                                              pw.Text('Thank you for your valuable contribution!', style: pw.TextStyle(fontSize: 16)),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                  await Printing.layoutPdf(onLayout: (format) async => pdf.save());
                                },
                                child: const Text('Download Certificate'),
                              ),
                            ],
                          ],
                        ),
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