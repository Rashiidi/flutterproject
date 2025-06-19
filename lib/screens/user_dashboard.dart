import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'event_discovery_screen.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'edit_profile_screen.dart';

class UserHome extends StatefulWidget {
  const UserHome({super.key});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  int _selectedIndex = 0;

  // Fetch events the user registered for
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
        eventData['attended'] = registration.data()?['attended'] == true;
        eventData['duration'] = eventData['duration'] ?? 1;
        registeredEvents.add(eventData);
      }
    }
    return registeredEvents;
  }

  // Fetch user profile info
  Future<Map<String, dynamic>?> fetchUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return doc.data();
  }

  // Fetch profile for DrawerHeader
  Future<Map<String, dynamic>?> fetchProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return doc.data();
  }

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
        title: const Text("Volunteer Dashboard"),
        backgroundColor: Colors.deepPurple.shade700,
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
          color: Colors.deepPurple.shade700,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                child: FutureBuilder<Map<String, dynamic>?>(
                  future: fetchProfile(),
                  builder: (context, snapshot) {
                    final data = snapshot.data;
                    final profileImageUrl = data?['profileImageUrl'] as String?;
                    final displayName = data?['displayName'] ?? user?.displayName ?? 'Volunteer';
                    final email = data?['email'] ?? user?.email ?? '';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundImage: (profileImageUrl != null && profileImageUrl.isNotEmpty)
                              ? NetworkImage(profileImageUrl)
                              : null,
                          child: (profileImageUrl == null || profileImageUrl.isEmpty)
                              ? const Icon(Icons.person, size: 32)
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          displayName,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          email,
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    );
                  },
                ),
              ),
              _drawerItem(Icons.event_available, 'Registered Events', 0),
              _drawerItem(Icons.search, 'Discover Events', 1),
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
            ? _RegisteredEventsScreen(
                fetchUserProfile: fetchUserProfile,
                fetchRegisteredEvents: fetchRegisteredEvents,
              )
            : const EventDiscoveryScreen(),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
      selected: _selectedIndex == index,
      selectedTileColor: Colors.deepPurple.shade900.withOpacity(0.3),
      onTap: () => _onSelect(index),
    );
  }
}

// Registered Events screen with profile and event cards
class _RegisteredEventsScreen extends StatelessWidget {
  final Future<Map<String, dynamic>?> Function() fetchUserProfile;
  final Future<List<Map<String, dynamic>>> Function() fetchRegisteredEvents;

  const _RegisteredEventsScreen({
    required this.fetchUserProfile,
    required this.fetchRegisteredEvents,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // Volunteer Profile Section
        FutureBuilder<Map<String, dynamic>?>(
          future: fetchUserProfile(),
          builder: (context, snapshot) {
            final profile = snapshot.data;
            final hours = profile?['serviceHours'] ?? 0;
            final profileImageUrl = profile?['profileImageUrl'] as String?;
            return Card(
              margin: const EdgeInsets.all(16),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: (profileImageUrl != null && profileImageUrl.isNotEmpty)
                          ? NetworkImage(profileImageUrl)
                          : null,
                      child: (profileImageUrl == null || profileImageUrl.isEmpty)
                          ? const Icon(Icons.person, size: 32)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile?['displayName'] ?? user?.displayName ?? 'No Name',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(profile?['email'] ?? user?.email ?? ''),
                          if ((profile?['phone'] ?? '').toString().isNotEmpty)
                            Text('Phone: ${profile?['phone']}'),
                          if ((profile?['bio'] ?? '').toString().isNotEmpty)
                            Text('Bio: ${profile?['bio']}'),
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
        const SizedBox(height: 8),
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
                    elevation: 3,
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
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.blueGrey,
                                ),
                              ),
                            ),
                        ],
                      ),
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple.shade100,
                              foregroundColor: Colors.deepPurple.shade900,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              textStyle: const TextStyle(fontSize: 12),
                            ),
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
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber.shade100,
                                foregroundColor: Colors.amber.shade900,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                textStyle: const TextStyle(fontSize: 12),
                              ),
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
    );
  }
}