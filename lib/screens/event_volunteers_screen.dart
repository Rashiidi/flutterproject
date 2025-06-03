import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EventVolunteersScreen extends StatelessWidget {
  final String eventId;
  final String eventTitle;
  const EventVolunteersScreen({super.key, required this.eventId, required this.eventTitle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Volunteers for "$eventTitle"'),
        backgroundColor: Colors.teal.shade700,
        elevation: 0,
      ),
      body: Container(
        color: Colors.teal.shade50,
        child: StreamBuilder<QuerySnapshot>(
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
                final volunteerId = docs[index].id;
                final attended = data['attended'] == true;
                final regDate = data['registeredAt'] != null
                    ? (data['registeredAt'] as Timestamp).toDate().toString().split(' ').first
                    : '';
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: attended ? Colors.green.shade100 : Colors.teal.shade100,
                      child: Icon(
                        attended ? Icons.check_circle : Icons.person,
                        color: attended ? Colors.green : Colors.teal.shade900,
                      ),
                    ),
                    title: Text(
                      data['displayName'] ?? 'No Name',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['email'] ?? '', style: const TextStyle(fontSize: 13)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Chip(
                              label: Text(
                                data['role'] ?? 'Member',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              backgroundColor: Colors.teal.shade100,
                            ),
                            const SizedBox(width: 8),
                            if (attended)
                              const Chip(
                                label: Text('Attended', style: TextStyle(color: Colors.white)),
                                backgroundColor: Colors.green,
                              ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        // Registration date
                        Text(regDate, style: const TextStyle(fontWeight: FontWeight.bold)),
                        // View Profile Button
                        IconButton(
                          icon: const Icon(Icons.info_outline),
                          tooltip: 'View Profile',
                          onPressed: () async {
                            final userDoc = await FirebaseFirestore.instance.collection('users').doc(volunteerId).get();
                            final userData = userDoc.data();
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(userData?['displayName'] ?? 'Volunteer Profile'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Email: ${userData?['email'] ?? ''}'),
                                    Text('Service Hours: ${userData?['serviceHours'] ?? 0}'),
                                    // Add more profile fields if needed
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        // Assign Role Dropdown
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('events')
                              .doc(eventId)
                              .collection('registrations')
                              .doc(volunteerId)
                              .snapshots(),
                          builder: (context, snap) {
                            final data = snap.data?.data() as Map<String, dynamic>?;
                            String currentRole = data?['role'] ?? 'Member';
                            return DropdownButton<String>(
                              value: currentRole,
                              items: ['Member', 'Team Lead', 'Photographer']
                                  .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                                  .toList(),
                              onChanged: (role) {
                                FirebaseFirestore.instance
                                    .collection('events')
                                    .doc(eventId)
                                    .collection('registrations')
                                    .doc(volunteerId)
                                    .update({'role': role});
                              },
                              underline: Container(),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                              dropdownColor: Colors.white,
                            );
                          },
                        ),
                        // Mark Attendance Button or Attended Icon
                        attended
                            ? const SizedBox.shrink()
                            : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal.shade100,
                                  foregroundColor: Colors.teal.shade900,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  textStyle: const TextStyle(fontSize: 12),
                                ),
                                onPressed: () async {
                                  // 1. Get event duration
                                  final eventDoc = await FirebaseFirestore.instance
                                      .collection('events')
                                      .doc(eventId)
                                      .get();
                                  final eventData = eventDoc.data() as Map<String, dynamic>;
                                  final double duration = (eventData['duration'] is int)
                                      ? (eventData['duration'] as int).toDouble()
                                      : (eventData['duration'] is double)
                                          ? eventData['duration']
                                          : double.tryParse(eventData['duration'].toString()) ?? 1;

                                  // 2. Mark attendance
                                  await FirebaseFirestore.instance
                                      .collection('events')
                                      .doc(eventId)
                                      .collection('registrations')
                                      .doc(volunteerId)
                                      .update({'attended': true});

                                  // 3. Update volunteer's total hours
                                  final userRef = FirebaseFirestore.instance.collection('users').doc(volunteerId);
                                  await FirebaseFirestore.instance.runTransaction((transaction) async {
                                    final userSnapshot = await transaction.get(userRef);
                                    final prevHours = (userSnapshot.data()?['serviceHours'] ?? 0).toDouble();
                                    transaction.update(userRef, {'serviceHours': prevHours + duration});
                                  });
                                },
                                child: const Text('Mark Attendance'),
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
    );
  }
}