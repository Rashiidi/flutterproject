import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../helpers/location_helper.dart';
import 'package:geolocator/geolocator.dart';

class EventDiscoveryScreen extends StatefulWidget {
  const EventDiscoveryScreen({super.key});

  @override
  State<EventDiscoveryScreen> createState() => _EventDiscoveryScreenState();
}

class _EventDiscoveryScreenState extends State<EventDiscoveryScreen> {
  Position? _userPosition;
  double _filterRadius = 10000; // 10km default
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  // Get the user's current location
  Future<void> _fetchLocation() async {
    final pos = await LocationHelper.getCurrentLocation();
    setState(() {
      _userPosition = pos;
    });
  }

  // Register the current user for an event
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

  // Check if the current user is already registered for an event
  Future<bool> isRegistered(String eventId, String userId) async {
    final doc = await FirebaseFirestore.instance
        .collection('events')
        .doc(eventId)
        .collection('registrations')
        .doc(userId)
        .get();
    return doc.exists;
  }

  // Helper to get NGO name by ID
  Future<String> getNgoName(String ngoId) async {
    if (ngoId.isEmpty) return '';
    final doc = await FirebaseFirestore.instance.collection('users').doc(ngoId).get();
    return doc.data()?['displayName'] ?? 'NGO';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Events'),
        backgroundColor: Colors.deepPurple.shade700,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Show a loading message while fetching location
          if (_userPosition == null)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Fetching your location...'),
            ),
          // Slider to filter events by distance
          if (_userPosition != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const Text('Show events within:'),
                  Slider(
                    value: _filterRadius,
                    min: 1000,
                    max: 50000,
                    divisions: 49,
                    label: '${(_filterRadius / 1000).toStringAsFixed(1)} km',
                    onChanged: (v) => setState(() => _filterRadius = v),
                  ),
                  Text('${(_filterRadius / 1000).toStringAsFixed(1)} km'),
                ],
              ),
            ),
          // Search bar for title/location
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by title or location...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
            ),
          ),
          // Main event list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
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
                // Filter events by distance if location is available
                var filteredDocs = _userPosition == null
                    ? docs
                    : docs.where((doc) {
                        final event = doc.data() as Map<String, dynamic>;
                        if (event['latitude'] == null || event['longitude'] == null) return false;
                        final distance = LocationHelper.distanceBetween(
                          _userPosition!.latitude,
                          _userPosition!.longitude,
                          (event['latitude'] as num).toDouble(),
                          (event['longitude'] as num).toDouble(),
                        );
                        return distance <= _filterRadius;
                      }).toList();

                // Filter by search query (title or location)
                if (_searchQuery.isNotEmpty) {
                  filteredDocs = filteredDocs.where((doc) {
                    final event = doc.data() as Map<String, dynamic>;
                    final title = (event['title'] ?? '').toString().toLowerCase();
                    final location = (event['location'] ?? '').toString().toLowerCase();
                    return title.contains(_searchQuery) || location.contains(_searchQuery);
                  }).toList();
                }

                if (filteredDocs.isEmpty) {
                  return const Center(child: Text('No nearby events found.'));
                }

                // Build the event cards
                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final event = filteredDocs[index].data() as Map<String, dynamic>;
                    final eventId = filteredDocs[index].id;
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
                    final isApproved = event['approved'] != false;
                    final ngoId = event['ngoId'] ?? '';
                    final eventImage = event['imageUrl'] ??
                        'https://images.unsplash.com/photo-1465101046530-73398c7f28ca?auto=format&fit=crop&w=400&q=80'; // Placeholder

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Event image (from Firestore or placeholder)
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                            child: Image.network(
                              eventImage,
                              height: 140,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: 140,
                                color: Colors.grey.shade200,
                                child: const Center(child: Icon(Icons.image, size: 48, color: Colors.grey)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Event icon
                                CircleAvatar(
                                  backgroundColor: Colors.deepPurple.shade100,
                                  child: const Icon(Icons.event, color: Colors.deepPurple),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        event['title'] ?? '',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold, fontSize: 18),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(event['description'] ?? '',
                                          style: const TextStyle(fontSize: 14)),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on, size: 16, color: Colors.blueGrey),
                                          const SizedBox(width: 2),
                                          Text(event['location'] ?? '',
                                              style: const TextStyle(fontSize: 13)),
                                          const SizedBox(width: 12),
                                          const Icon(Icons.calendar_today, size: 16, color: Colors.blueGrey),
                                          const SizedBox(width: 2),
                                          Text(dateStr, style: const TextStyle(fontSize: 13)),
                                        ],
                                      ),
                                      // Show distance if available
                                      if (event['latitude'] != null &&
                                          event['longitude'] != null &&
                                          _userPosition != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4.0),
                                          child: Text(
                                            'Distance: ${(LocationHelper.distanceBetween(
                                              _userPosition!.latitude,
                                              _userPosition!.longitude,
                                              (event['latitude'] as num).toDouble(),
                                              (event['longitude'] as num).toDouble(),
                                            ) / 1000).toStringAsFixed(2)} km',
                                            style: const TextStyle(color: Colors.blueGrey, fontSize: 13),
                                          ),
                                        ),
                                      const SizedBox(height: 6),
                                      // Show NGO name (fetched by ID)
                                      FutureBuilder<String>(
                                        future: getNgoName(ngoId),
                                        builder: (context, ngoSnap) {
                                          if (!ngoSnap.hasData) {
                                            return const SizedBox(height: 18);
                                          }
                                          return Row(
                                            children: [
                                              const Icon(Icons.account_balance, size: 16, color: Colors.teal),
                                              const SizedBox(width: 4),
                                              Text(
                                                ngoSnap.data!,
                                                style: const TextStyle(
                                                    fontSize: 13, fontWeight: FontWeight.w500),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                // Status chip (Approved/Pending)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Chip(
                                      label: Text(
                                        isApproved ? 'Approved' : 'Pending',
                                        style: TextStyle(
                                            color: isApproved ? Colors.white : Colors.black87,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      backgroundColor:
                                          isApproved ? Colors.green : Colors.orange.shade200,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Register button or Registered text
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 16, right: 16, bottom: 16, top: 0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                user == null
                                    ? const SizedBox.shrink()
                                    : FutureBuilder<bool>(
                                        future: isRegistered(eventId, user.uid),
                                        builder: (context, regSnapshot) {
                                          if (!regSnapshot.hasData) {
                                            return const SizedBox(
                                                width: 100,
                                                child: Center(
                                                    child: CircularProgressIndicator(strokeWidth: 2)));
                                          }
                                          if (regSnapshot.data == true) {
                                            return const Text(
                                              'Registered',
                                              style: TextStyle(
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.bold),
                                            );
                                          }
                                          return ElevatedButton.icon(
                                            onPressed: () => registerForEvent(eventId),
                                            icon: const Icon(Icons.how_to_reg),
                                            label: const Text('Register'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.deepPurple.shade100,
                                              foregroundColor: Colors.deepPurple.shade900,
                                              padding: const EdgeInsets.symmetric(horizontal: 12),
                                            ),
                                          );
                                        },
                                      ),
                              ],
                            ),
                          ),
                        ],
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