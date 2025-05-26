import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'create_event_screen.dart';
import 'event_volunteers_screen.dart';
import 'event_feedback_screen.dart';

class NgoHome extends StatelessWidget {
  const NgoHome({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Welcome to the  NGO"),
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
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateEventScreen()),
                );
              },
              child: const Text('Create New Event'),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Your Events',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            child: user == null
                ? const Center(child: Text('Not logged in'))
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('events')
                        .where('ngoId', isEqualTo: user.uid)
                        .orderBy('date')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('No events yet.'));
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
                              subtitle: Text(event['description'] ?? ''),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(dateStr),
                                  IconButton(
                                    icon: const Icon(Icons.group),
                                    tooltip: 'View Volunteers',
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => EventVolunteersScreen(
                                            eventId: eventId,
                                            eventTitle: event['title'] ?? '',
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.feedback),
                                    tooltip: 'View Feedback',
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => EventFeedbackScreen(
                                            eventId: eventId,
                                            eventTitle: event['title'] ?? '',
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    tooltip: 'Edit Event',
                                    onPressed: () async {
                                      final titleCtrl = TextEditingController(text: event['title']);
                                      final descCtrl = TextEditingController(text: event['description']);
                                      final locationCtrl = TextEditingController(text: event['location']);
                                      final durationCtrl = TextEditingController(
                                        text: (event['duration'] ?? 1).toString(),
                                      );
                                      DateTime? selectedDate;
                                      if (event['date'] is Timestamp) {
                                        selectedDate = (event['date'] as Timestamp).toDate();
                                      } else if (event['date'] is String) {
                                        selectedDate = DateTime.tryParse(event['date']);
                                      }
                                      await showDialog(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            title: const Text('Edit Event'),
                                            content: SingleChildScrollView(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  TextField(
                                                    controller: titleCtrl,
                                                    decoration: const InputDecoration(labelText: 'Title'),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  TextField(
                                                    controller: descCtrl,
                                                    decoration: const InputDecoration(labelText: 'Description'),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  TextField(
                                                    controller: locationCtrl,
                                                    decoration: const InputDecoration(labelText: 'Location'),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  TextField(
                                                    controller: durationCtrl,
                                                    keyboardType: TextInputType.number,
                                                    decoration: const InputDecoration(labelText: 'Duration (hours)'),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  ElevatedButton(
                                                    onPressed: () async {
                                                      final picked = await showDatePicker(
                                                        context: context,
                                                        initialDate: selectedDate ?? DateTime.now(),
                                                        firstDate: DateTime(2020),
                                                        lastDate: DateTime(2100),
                                                      );
                                                      if (picked != null) {
                                                        selectedDate = picked;
                                                      }
                                                    },
                                                    child: Text(selectedDate == null
                                                        ? 'Pick Date'
                                                        : 'Date: ${selectedDate!.toLocal().toString().split(' ').first}'),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () async {
                                                  await FirebaseFirestore.instance
                                                      .collection('events')
                                                      .doc(eventId)
                                                      .update({
                                                    'title': titleCtrl.text,
                                                    'description': descCtrl.text,
                                                    'location': locationCtrl.text,
                                                    'duration': double.tryParse(durationCtrl.text) ?? 1,
                                                    'date': selectedDate?.toIso8601String() ?? event['date'],
                                                  });
                                                  Navigator.pop(context);
                                                },
                                                child: const Text('Save'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    tooltip: 'Delete Event',
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Delete Event'),
                                          content: const Text('Are you sure you want to delete this event? This cannot be undone.'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, false),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, true),
                                              child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        await FirebaseFirestore.instance.collection('events').doc(eventId).delete();
                                      }
                                    },
                                  ),
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