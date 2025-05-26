// ...existing imports...
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final locationCtrl = TextEditingController();
  final durationCtrl = TextEditingController(); // <-- Add this
  DateTime? eventDate;

  Future<void> createEvent() async {
    final ngoId = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('events').add({
      'title': titleCtrl.text,
      'description': descCtrl.text,
      'location': locationCtrl.text,
      'date': eventDate?.toIso8601String(),
      'ngoId': ngoId,
      'duration': double.tryParse(durationCtrl.text) ?? 1, // <-- Save duration
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Event')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
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
                  initialDate: eventDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() {
                    eventDate = picked;
                  });
                }
              },
              child: Text(eventDate == null
                  ? 'Pick Date'
                  : 'Date: ${eventDate!.toLocal().toString().split(' ').first}'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: createEvent,
              child: const Text('Create Event'),
            ),
          ],
        ),
      ),
    );
  }
}