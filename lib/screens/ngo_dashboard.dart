import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'create_event_screen.dart';
import 'event_volunteers_screen.dart';
import 'event_feedback_screen.dart';
import 'edit_profile_screen.dart'; // <-- Import the profile editing screen

class NgoHome extends StatefulWidget {
  const NgoHome({super.key});

  @override
  State<NgoHome> createState() => _NgoHomeState();
}

class _NgoHomeState extends State<NgoHome> {
  int _selectedIndex = 0;

  final List<String> _titles = [
    'My Events',
    'Create Event',
  ];

  // Handle sidebar navigation
  void _onSelect(int index) {
    setState(() {
      _selectedIndex = index;
      Navigator.pop(context); // Close the drawer
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: Colors.green.shade700,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.green.shade700,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Drawer header with NGO info
              DrawerHeader(
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.volunteer_activism, size: 48, color: Colors.white),
                    const SizedBox(height: 8),
                    Text(
                      user?.displayName ?? 'NGO',
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              // Sidebar navigation items
              _drawerItem(Icons.event, 'My Events', 0),
              _drawerItem(Icons.add_circle, 'Create Event', 1),
              ListTile(
                leading: const Icon(Icons.person, color: Colors.white),
                title: const Text('Edit Profile', style: TextStyle(color: Colors.white, fontSize: 16)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                  );
                },
              ),
              const Divider(color: Colors.white70),
              // Logout button at the bottom of the drawer
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.white),
                title: const Text('Logout', style: TextStyle(color: Colors.white, fontSize: 16)),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.of(context).pushReplacementNamed('/login');
                },
              ),
            ],
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _selectedIndex == 0
            ? _MyEventsScreen(user: user)
            : const CreateEventScreen(),
      ),
    );
  }

  // Helper for sidebar items
  Widget _drawerItem(IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
      selected: _selectedIndex == index,
      selectedTileColor: Colors.green.shade900.withOpacity(0.3),
      onTap: () => _onSelect(index),
    );
  }
}

// Screen to show all events created by this NGO
class _MyEventsScreen extends StatelessWidget {
  final User? user;
  const _MyEventsScreen({required this.user});

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Center(child: Text('Not logged in'));
    }
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('events')
            .where('ngoId', isEqualTo: user!.uid)
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
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text(
                    event['title'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event['description'] ?? ''),
                      if ((event['report'] ?? '').isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Event Report: ${event['report']}',
                            style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.blueGrey),
                          ),
                        ),
                    ],
                  ),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      // Show event date
                      Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold)),
                      // View volunteers for this event
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
                      // View feedback for this event
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
                      // Post or edit event report
                      IconButton(
                        icon: const Icon(Icons.article),
                        tooltip: 'Post/Edit Report',
                        onPressed: () async {
                          final eventDoc = await FirebaseFirestore.instance.collection('events').doc(eventId).get();
                          final currentReport = eventDoc.data()?['report'] ?? '';
                          final ctrl = TextEditingController(text: currentReport);
                          final result = await showDialog<String>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Event Report/Update'),
                              content: TextField(
                                controller: ctrl,
                                maxLines: 6,
                                decoration: const InputDecoration(labelText: 'Enter event report or update'),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, null),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, ctrl.text.trim()),
                                  child: const Text('Save'),
                                ),
                              ],
                            ),
                          );
                          if (result != null) {
                            await FirebaseFirestore.instance.collection('events').doc(eventId).update({'report': result});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Event report updated!')),
                            );
                          }
                        },
                      ),
                      // Edit event details
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
                      // Delete event
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
    );
  }
}