import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NgoHome extends StatelessWidget {
  const NgoHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("NGO Home"),
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
      body: const Center(child: Text("Welcome, NGO!")),
    );
  }
}