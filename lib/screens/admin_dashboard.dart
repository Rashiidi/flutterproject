import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import your new settings screen
import 'admin_settings_screen.dart';

// Main Admin Dashboard Widget
class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _selectedIndex = 0;

  // List of screens for navigation
  final List<Widget> _screens = [
    AllUsersScreen(),
    AllEventsScreen(),
    AnalyticsScreen(),
    AdminSettingsScreen(), // Add settings screen here
  ];

  // Titles for AppBar
  final List<String> _titles = [
    'All Users',
    'All Events',
    'Analytics',
    'Settings', // Add settings title here
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: Colors.blue.shade700,
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
          color: Colors.blue.shade700,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Drawer header with admin info
              DrawerHeader(
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.admin_panel_settings, size: 48, color: Colors.white),
                    SizedBox(height: 8),
                    Text('Admin Dashboard', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              // Sidebar navigation items
              _drawerItem(Icons.people, 'All Users', 0),
              _drawerItem(Icons.event, 'All Events', 1),
              _drawerItem(Icons.bar_chart, 'Analytics', 2),
              _drawerItem(Icons.settings, 'Settings', 3), // Add settings item
              const Divider(color: Colors.white70),
              // Logout button
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
      // Main content area switches between screens
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Container(
          color: Colors.grey.shade100,
          child: _screens[_selectedIndex],
        ),
      ),
    );
  }

  // Helper for sidebar items
  Widget _drawerItem(IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
      selected: _selectedIndex == index,
      selectedTileColor: Colors.blue.shade900.withOpacity(0.3),
      onTap: () => _onSelect(index),
    );
  }
}

// ===================== ALL USERS SCREEN WITH MODERATION =====================
class AllUsersScreen extends StatelessWidget {
  const AllUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No users found.'));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final userDoc = docs[index];
              final user = userDoc.data() as Map<String, dynamic>;
              final userId = userDoc.id;
              final isBanned = user['banned'] == true;
              final role = (user['role'] ?? 'user').toString().toLowerCase();
              final isNGO = role == 'ngo' || role == 'verified ngo';
              final isVerified = role == 'verified ngo';

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isBanned ? Colors.red.shade200 : Colors.blue.shade200,
                    child: Icon(Icons.person, color: isBanned ? Colors.red : Colors.blue.shade900),
                  ),
                  title: Text(
                    user['displayName'] ?? 'No Name',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user['email'] ?? '', style: const TextStyle(fontSize: 13)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Role chip (user, ngo, admin, verified ngo)
                          Chip(
                            label: Text(role[0].toUpperCase() + role.substring(1)),
                            backgroundColor: isVerified
                                ? Colors.blue.shade100
                                : isNGO
                                    ? Colors.green.shade100
                                    : Colors.grey.shade200,
                            avatar: isVerified
                                ? const Icon(Icons.verified, color: Colors.blue, size: 18)
                                : null,
                          ),
                          // Banned chip if user is banned
                          if (isBanned)
                            const Padding(
                              padding: EdgeInsets.only(left: 8.0),
                              child: Chip(
                                label: Text('Banned', style: TextStyle(color: Colors.white)),
                                backgroundColor: Colors.red,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      // Dropdown to change user role
                      DropdownButton<String>(
                        value: ['user', 'ngo', 'admin', 'verified ngo'].contains(role) ? role : 'user',
                        items: ['user', 'ngo', 'admin', 'verified ngo']
                            .map((r) => DropdownMenuItem(
                                  value: r,
                                  child: Text(r[0].toUpperCase() + r.substring(1)),
                                ))
                            .toList(),
                        onChanged: (newRole) {
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(userId)
                              .update({'role': newRole});
                        },
                        underline: Container(),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                        dropdownColor: Colors.white,
                      ),
                      // Verify/Unverify NGO button
                      if (isNGO)
                        IconButton(
                          icon: Icon(
                            isVerified ? Icons.verified : Icons.verified_outlined,
                            color: isVerified ? Colors.blue : Colors.grey,
                          ),
                          tooltip: isVerified ? 'Unverify NGO' : 'Verify NGO',
                          onPressed: () {
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(userId)
                                .update({'role': isVerified ? 'ngo' : 'verified ngo'});
                          },
                        ),
                      // Ban/Unban user button
                      IconButton(
                        icon: Icon(
                          isBanned ? Icons.lock_open : Icons.block,
                          color: isBanned ? Colors.green : Colors.red,
                          semanticLabel: isBanned ? 'Unban User' : 'Ban',
                        ),
                        tooltip: isBanned ? 'Unban User' : 'Ban User',
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(userId)
                              .update({'banned': !isBanned});
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

// ===================== ALL EVENTS SCREEN WITH MODERATION =====================
class AllEventsScreen extends StatelessWidget {
  const AllEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('events').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No events found.'));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final eventDoc = docs[index];
              final event = eventDoc.data() as Map<String, dynamic>;
              final eventId = eventDoc.id;
              final isApproved = event['approved'] != false; // default true if not set

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isApproved ? Colors.green.shade100 : Colors.orange.shade100,
                    child: Icon(
                      Icons.event,
                      color: isApproved ? Colors.green : Colors.orange,
                    ),
                  ),
                  title: Text(
                    event['title'] ?? 'No Title',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event['description'] ?? '', style: const TextStyle(fontSize: 13)),
                      if (event['ngoId'] != null)
                        Text('NGO ID: ${event['ngoId']}', style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (event['approved'] == false)
                            const Chip(
                              label: Text('Pending Approval', style: TextStyle(color: Colors.white)),
                              backgroundColor: Colors.orange,
                            ),
                          if (event['approved'] == true)
                            const Chip(
                              label: Text('Approved', style: TextStyle(color: Colors.white)),
                              backgroundColor: Colors.green,
                            ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      // Approve/Unapprove event button
                      IconButton(
                        icon: Icon(
                          isApproved ? Icons.check_circle : Icons.hourglass_empty,
                          color: isApproved ? Colors.green : Colors.orange,
                        ),
                        tooltip: isApproved ? 'Unapprove Event' : 'Approve Event',
                        onPressed: () {
                          FirebaseFirestore.instance
                              .collection('events')
                              .doc(eventId)
                              .update({'approved': !isApproved});
                        },
                      ),
                      // Delete event button
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Delete Event',
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Event'),
                              content: const Text('Are you sure you want to delete this event?'),
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

// ===================== ADVANCED ANALYTICS SCREEN =====================
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  // Helper to get count of documents in a collection
  Future<int> _getCount(String collection) async {
    final snap = await FirebaseFirestore.instance.collection(collection).get();
    return snap.docs.length;
  }

  // Helper to get count of verified NGOs
  Future<int> _getVerifiedNGOs() async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'verified ngo')
        .get();
    return snap.docs.length;
  }

  // Helper to get count of pending events
  Future<int> _getPendingEvents() async {
    final snap = await FirebaseFirestore.instance
        .collection('events')
        .where('approved', isEqualTo: false)
        .get();
    return snap.docs.length;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: FutureBuilder(
        future: Future.wait([
          _getCount('users'),
          _getCount('events'),
          _getVerifiedNGOs(),
          _getPendingEvents(),
        ]),
        builder: (context, AsyncSnapshot<List<int>> snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final userCount = snapshot.data![0];
          final eventCount = snapshot.data![1];
          final verifiedNGOs = snapshot.data![2];
          final pendingEvents = snapshot.data![3];
          return GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
            children: [
              _statCard(Icons.people, 'Total Users', userCount, Colors.blue),
              _statCard(Icons.event, 'Total Events', eventCount, Colors.green),
              _statCard(Icons.verified, 'Verified NGOs', verifiedNGOs, Colors.indigo),
              _statCard(Icons.hourglass_empty, 'Pending Events', pendingEvents, Colors.orange),
            ],
          );
        },
      ),
    );
  }

  // Helper to build a stat card
  Widget _statCard(IconData icon, String label, int value, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(
                '$value',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
              ),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}