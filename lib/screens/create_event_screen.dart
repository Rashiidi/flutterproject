import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final locationCtrl = TextEditingController();
  final durationCtrl = TextEditingController();
  DateTime? selectedDate;
  double? _latitude;
  double? _longitude;
  bool _gettingLocation = false;

  Future<void> _getCurrentLocation() async {
    setState(() => _gettingLocation = true);
    try {
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not get location: $e')),
      );
    }
    setState(() => _gettingLocation = false);
  }

  Future<void> _saveEvent() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('events').add({
      'title': titleCtrl.text,
      'description': descCtrl.text,
      'location': locationCtrl.text,
      'duration': double.tryParse(durationCtrl.text) ?? 1,
      'date': selectedDate?.toIso8601String(),
      'ngoId': user.uid,
      'latitude': _latitude,
      'longitude': _longitude,
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Event')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
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
              decoration: const InputDecoration(labelText: 'Location (address/venue)'),
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
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() => selectedDate = picked);
                }
              },
              child: Text(selectedDate == null
                  ? 'Pick Date'
                  : 'Date: ${selectedDate!.toLocal().toString().split(' ').first}'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _gettingLocation ? null : _getCurrentLocation,
              child: Text(_latitude == null
                  ? (_gettingLocation ? 'Getting Location...' : 'Use Current Location')
                  : 'Location Set (${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)})'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveEvent,
              child: const Text('Create Event'),
            ),
          ],
        ),
      ),
    );
  }
}