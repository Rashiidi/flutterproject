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
              final volunteerId = docs[index].id;
              final attended = data['attended'] == true;
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(data['displayName'] ?? 'No Name'),
                subtitle: Text(data['email'] ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      data['registeredAt'] != null
                          ? (data['registeredAt'] as Timestamp)
                              .toDate()
                              .toString()
                              .split(' ')
                              .first
                          : '',
                    ),
                    const SizedBox(width: 8),
                    attended
                        ? const Icon(Icons.check_circle, color: Colors.green, semanticLabel: 'Attended')
                        : ElevatedButton(
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
              );
            },
          );
        },
      ),
    );
  }
}